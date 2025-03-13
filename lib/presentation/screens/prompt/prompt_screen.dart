import 'package:flutter/material.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  bool isPrivateSelected = true;
  bool showFavoritesOnly = false;
  Set<String> favoritePrompts = {};

  void _showDeleteConfirmation(BuildContext context, String itemName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Delete Dialog",
      barrierColor: Colors.black.withAlpha(50),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Delete Prompt',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message
                    Text(
                      'Are you sure you want to delete "$itemName"? This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Delete Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$itemName deleted'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.black87,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sample data for prompt items
    final List<Map<String, dynamic>> prompts = [
      {
        'name': 'Professional Email Writer',
        'description': 'Generate formal business emails with proper etiquette',
        'content': '''Create a professional email that is:
- Clear and concise
- Uses appropriate business language
- Maintains professional tone
- Includes proper greeting and signature

Context: [User's specific situation]
Key points to address: [Main message points]
Tone: [Formal/Semi-formal]
''',
        'category': 'Business',
        'language': 'English',
        'isPublic': true,
        'avatarColor': Colors.blue,
      },
      {
        'name': 'Code Refactoring Assistant',
        'description': 'AI helper for improving code quality and readability',
        'content': '''Please help refactor this code to:
1. Follow best practices
2. Improve performance
3. Enhance readability
4. Apply SOLID principles
5. Add appropriate comments

Original code:
[User's code goes here]
''',
        'category': 'Coding',
        'language': 'English',
        'isPublic': true,
        'avatarColor': Colors.green,
      },
      {
        'name': 'Creative Story Starter',
        'description':
            'Generate engaging story beginnings for creative writing',
        'content': '''Help me write a creative story with these elements:
- Genre: [Fantasy/Mystery/Romance]
- Main character traits: [Personality traits]
- Setting: [Time and place]
- Tone: [Dark/Light/Humorous]
- Key themes: [Main story themes]

Please start the story with an engaging opening paragraph.''',
        'category': 'Writing',
        'language': 'English',
        'isPublic': false,
        'avatarColor': Colors.purple,
      },
      {
        'name': 'Study Notes Generator',
        'description': 'Create organized study materials from any topic',
        'content': '''Please create comprehensive study notes for:

Topic: [Subject area]
Key concepts to cover:
1. [Main point 1]
2. [Main point 2]
3. [Main point 3]

Include:
- Definitions
- Key examples
- Important relationships
- Summary points''',
        'category': 'Education',
        'language': 'English',
        'isPublic': true,
        'avatarColor': Colors.orange,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Prompt',
          style: TextStyle(
            color: Color(0xFF3B5998),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF415DF2), Color(0xFF5B8AF5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF415DF2).withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/create-prompt');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Category, Title, Content,..',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Prompt count and filter options
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  // Favorites filter
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showFavoritesOnly = !showFavoritesOnly;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            showFavoritesOnly
                                ? const Color(0xFF415DF2)
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showFavoritesOnly
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color:
                                showFavoritesOnly
                                    ? Colors.white
                                    : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Favorites',
                            style: TextStyle(
                              color:
                                  showFavoritesOnly
                                      ? Colors.white
                                      : Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Private/Public filter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isPrivateSelected = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isPrivateSelected
                                        ? const Color(0xFF415DF2)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Private',
                                style: TextStyle(
                                  color:
                                      isPrivateSelected
                                          ? Colors.white
                                          : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isPrivateSelected = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    !isPrivateSelected
                                        ? const Color(0xFF415DF2)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Public',
                                style: TextStyle(
                                  color:
                                      !isPrivateSelected
                                          ? Colors.white
                                          : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Prompt list
            Expanded(
              child: ListView.separated(
                itemCount: prompts.length,
                separatorBuilder:
                    (context, index) =>
                        const Divider(height: 1, color: Colors.transparent),
                itemBuilder: (context, index) {
                  final item = prompts[index];
                  final isStarred = favoritePrompts.contains(item['name']);

                  // Skip non-favorite items when showing favorites only
                  if (showFavoritesOnly && !isStarred) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Make the main content area tappable
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/update-prompt',
                                arguments:
                                    item, // Pass the prompt data to the update screen
                              );
                            },
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: item['avatarColor'] as Color,
                                  child: Text(
                                    item['name'].toString().substring(0, 1),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Name and description - with Expanded
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item['name'].toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['description'].toString(),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Star button
                        IconButton(
                          icon: Icon(
                            isStarred
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: isStarred ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isStarred) {
                                favoritePrompts.remove(item['name']);
                              } else {
                                favoritePrompts.add(item['name'].toString());
                              }
                            });

                            // Show feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isStarred
                                      ? 'Removed from favorites'
                                      : 'Added to favorites',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.black87,
                              ),
                            );
                          },
                        ),

                        // Delete button
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed:
                              () => _showDeleteConfirmation(
                                context,
                                item['name'].toString(),
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
