import 'package:flutter/material.dart';

enum MessageType { user, assistant }

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
              backgroundColor: const Color(
                0xFF6C63FF,
              ).withAlpha(26),
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: Color(0xFF6C63FF),
              ),
            )
          else if (!isUser)
            const SizedBox(width: 32),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6C63FF) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(
                      13,
                    ), 
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color:
                          isUser
                              ? Colors.white.withAlpha(
                                179,
                              ) 
                              : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (isUser && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: const Text(
                'W',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          else if (isUser)
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
