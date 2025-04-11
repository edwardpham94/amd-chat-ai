import 'package:amd_chat_ai/model/conversation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversationHistoryModal extends StatelessWidget {
  final List<Conversation> conversations;
  final Function(String) onConversationSelected;
  final bool isLoading;

  const ConversationHistoryModal({
    super.key,
    required this.conversations,
    required this.onConversationSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Conversation History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading conversations...'),
                ],
              ),
            )
          else if (conversations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No conversations found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return ListTile(
                    title: Text(
                      conversation.title.isEmpty
                          ? 'Untitled Conversation'
                          : conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateFormat(
                        'MMM d, yyyy • h:mm a',
                      ).format(conversation.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      onConversationSelected(conversation.id);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
