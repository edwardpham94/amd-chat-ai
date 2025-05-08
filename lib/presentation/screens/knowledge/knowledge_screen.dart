import 'package:flutter/material.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/new_button_widget.dart';

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

    return BaseScreen(
      title: 'Knowledge',
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // New Knowledge button and search bar row
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Knowledge',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                NewButton(
                  onTap: () {
                    Navigator.of(context).pushNamed('/create-knowledge');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Knowledge count
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
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  final item = knowledgeItems[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.05 * 2,
                            red: null,
                            green: null,
                            blue: null,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Document icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (item['avatarColor'] as Color).withValues(
                              alpha: 0.1 * 255,
                              red: null,
                              green: null,
                              blue: null,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: item['avatarColor'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                              const SizedBox(height: 4),
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
                        // Delete button
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 22,
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
