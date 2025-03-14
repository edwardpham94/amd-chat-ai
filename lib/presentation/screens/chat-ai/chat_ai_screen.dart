import 'package:amd_chat_ai/presentation/screens/widgets/chat-ai/prompt_template.dart';
import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _showWelcomeMessage = true;
  final List<Map<String, dynamic>> _aiModels = [
    {
      'name': 'GPT-3.5',
      'selected': false,
      'description': 'Fast & efficient for everyday tasks',
      'tokens': '4K context',
      'speed': 'Very Fast',
    },
    {
      'name': 'GPT-4',
      'selected': true,
      'description': 'Most capable model for complex tasks',
      'tokens': '8K context',
      'speed': 'Standard',
    },
    {
      'name': 'Claude',
      'selected': false,
      'description': 'Excellent at analysis & writing',
      'tokens': '100K context',
      'speed': 'Fast',
    },
    {
      'name': 'Gemini',
      'selected': false,
      'description': 'Strong at coding & mathematics',
      'tokens': '32K context',
      'speed': 'Fast',
    },
  ];
  final int _tokenCount = 30;

  String get _selectedModel {
    final selected = _aiModels.firstWhere((model) => model['selected'] == true);
    return selected['name'];
  }

  final List<Map<String, dynamic>> _promptTemplates = [
    {
      'title': 'AI Poetry Generation',
      'description': 'Create beautiful poems with AI assistance',
      'prompt': 'Write a poem about...',
    },
    {
      'title': 'English Vocabulary Learning Flashcard',
      'description': 'Create flashcards for language learning',
      'prompt': 'Create flashcards for the word...',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final message = _messageController.text;
      setState(() {
        _showWelcomeMessage = false;
        _messages.add({
          'message': message,
          'type': MessageType.user,
          'timestamp': DateTime.now(),
        });
      });

      // Simulate AI response after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;

        setState(() {
          _messages.add({
            'message':
                'I understand you want help with that. Let me assist you.',
            'type': MessageType.assistant,
            'timestamp': DateTime.now(),
          });
        });
      });

      _messageController.clear();
    }
  }

  void _changeAIModel(String modelName) {
    setState(() {
      for (var model in _aiModels) {
        model['selected'] = model['name'] == modelName;
      }
    });
    Navigator.of(context).pop();
  }

  void _showModelSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              "Select AI Model",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _aiModels.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final model = _aiModels[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Row(
                      children: [
                        Text(
                          model['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                model['selected']
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            model['speed'],
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  model['selected']
                                      ? Colors.blue
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          model['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model['tokens'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    leading: Radio<String>(
                      value: model['name'],
                      groupValue: _selectedModel,
                      onChanged: (value) => _changeAIModel(value!),
                    ),
                    onTap: () => _changeAIModel(model['name']),
                    selected: model['selected'],
                    selectedTileColor: Colors.blue.withOpacity(0.05),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Chat AI',
      body: Column(
        children: [
          // Model selector centered below title
          Center(
            child: TextButton(
              onPressed: _showModelSelectionDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedModel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
            ),
          ),
          // Existing chat content
          Expanded(
            child:
                _showWelcomeMessage
                    ? _buildWelcomeMessage()
                    : _buildChatMessages(),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Row(
          children: [
            Text('👋', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'Hi, good evening!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'I\'m Jarvis, your personal assistant.',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 32),
        const Text(
          'Don\'t know what to say? Use a prompt!',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 16),
        ..._promptTemplates.map(
          (template) => PromptTemplate(
            title: template['title'],
            description: template['description'],
            onTap: () => _handlePromptSelect(template['prompt']),
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return ChatMessage(
          message: message['message'],
          type: message['type'],
          timestamp: message['timestamp'],
          showAvatar:
              index == 0 || _messages[index - 1]['type'] != message['type'],
        );
      },
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything, press \'/\' for prompts...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.schedule),
                    color: Colors.grey,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.grey,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '🔥 $_tokenCount',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _handleSendMessage,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 16),
                      SizedBox(width: 4),
                      Text('Send'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePromptSelect(String prompt) {
    setState(() {
      _messageController.text = prompt;
    });
  }
}
