import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(
              alpha: 0.1 * 255,
              red: null,
              green: null,
              blue: null,
            ),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              onPressed: () {},
              color: Colors.grey,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: () {},
              color: Colors.grey,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: onSend,
              color: const Color(0xFF6C63FF),
            ),
          ],
        ),
      ),
    );
  }
}
