import 'package:flutter/material.dart';

enum MessageType { user, assistant, error }

class ChatMessage extends StatelessWidget {
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool showAvatar;

  const ChatMessage({
    super.key,
    required this.message,
    required this.type,
    required this.timestamp,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = type == MessageType.user;
    final isError = type == MessageType.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isError
                      ? Colors.red.shade100
                      : const Color(0xFF6C63FF).withAlpha(26),
              child: Icon(
                isError ? Icons.error_outline : Icons.smart_toy,
                size: 16,
                color: isError ? Colors.red : const Color(0xFF6C63FF),
              ),
            )
          else if (!isUser)
            const SizedBox(width: 32),

          const SizedBox(width: 8),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? Colors.blue.shade100
                        : isError
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isError ? Colors.red.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 32),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
