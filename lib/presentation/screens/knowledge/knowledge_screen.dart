import 'package:flutter/material.dart';

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

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
                      'Delete Knowledge',
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
    // Sample data for knowledge items
    final knowledgeItems = [
      {
        'name': 'Wade Warren',
        'description': 'Travel Bot',
        'avatarColor': Colors.lightBlue,
      },
      {
        'name': 'Wade Warren',
        'description': 'Work Bot',
        'avatarColor': Colors.deepPurple,
      },
      {
        'name': 'Esther Howard',
        'description': 'Study Bot',
        'avatarColor': Colors.teal,
      },
      {
        'name': 'Cameron Edw',
        'description': '24ctm',
        'avatarColor': Colors.amber,
      },
      {
        'name': 'Robert Fox',
        'description': 'birhan628@gmail.com',
        'avatarColor': Colors.brown,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Knowledge',
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
                    Navigator.of(context).pushNamed('/create-knowledge');
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
                  hintText: 'Search Knowledge',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Knowledge count and filter options
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  const Text(
                    '32 Knowledge Available',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Knowledge list
            Expanded(
              child: ListView.separated(
                itemCount: knowledgeItems.length,
                separatorBuilder:
                    (context, index) =>
                        const Divider(height: 1, color: Colors.transparent),
                itemBuilder: (context, index) {
                  final item = knowledgeItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                        // Delete button - with fixed width
                        SizedBox(
                          width: 48,
                          child: IconButton(
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
