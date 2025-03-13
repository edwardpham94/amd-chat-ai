import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';
import '../widgets/chat_input.dart';
import '../widgets/tag_chip.dart';

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _selectedTags = [];
  final List<String> _availableTags = ['using HTML', 'using CSS', 'JavaScript'];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      // Handle sending message
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Rak-GPT',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.smart_toy,
                      size: 40,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hello, Boss!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D5F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Am Ready For Help You',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D5F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask me anything what\'s are on your mind. Am here to assist you!',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6E6E9B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D5F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Please login to save your chats',
                    style: TextStyle(
                      color: Color(0xFF2D2D5F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  children:
                      _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return TagChip(
                          label: tag,
                          isSelected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          ChatInput(
            controller: _messageController,
            onSend: _handleSendMessage,
            hintText: 'Message AI Bot',
          ),
        ],
      ),
    );
  }
}
