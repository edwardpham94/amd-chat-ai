import 'package:amd_chat_ai/presentation/screens/widgets/app_sidebar.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/chat-ai/modal_selector.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/chat-ai/prompt_template.dart';
import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _showWelcomeMessage = true;
  String _selectedModel = 'GPT-4o mini';
  bool _showModelSelector = false;
  int _tokenCount = 30;

  final List<Map<String, dynamic>> _aiModels = [
    {
      'name': 'GPT-4o mini',
      'description':
          'OpenAI\'s latest model, very fast and great for most everyday tasks.',
      'cost': '1 Token',
      'icon': Icons.auto_awesome,
    },
    {
      'name': 'GPT-4o',
      'description': 'Most capable model for complex tasks.',
      'cost': '2 Tokens',
      'icon': Icons.auto_awesome,
    },
    {
      'name': 'Gemini 1.5 Flash',
      'description': 'Fast and efficient for quick responses.',
      'cost': '1 Token',
      'icon': Icons.flash_on,
    },
    {
      'name': 'Gemini 1.5 Pro',
      'description': 'Advanced model for complex reasoning.',
      'cost': '2 Tokens',
      'icon': Icons.psychology,
    },
    {
      'name': 'Claude 3 Haiku',
      'description': 'Efficient and precise responses.',
      'cost': '1 Token',
      'icon': Icons.brightness_auto,
    },
    {
      'name': 'Claude 3.5 Sonnet',
      'description': 'Advanced language understanding and generation.',
      'cost': '2 Tokens',
      'icon': Icons.brightness_7,
    },
  ];

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

  void _handleModelSelect(String model) {
    setState(() {
      _selectedModel = model;
      _showModelSelector = false;
    });
  }

  void _handlePromptSelect(String prompt) {
    setState(() {
      _messageController.text = prompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            setState(() {
              _showModelSelector = !_showModelSelector;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _aiModels.firstWhere(
                  (m) => m['name'] == _selectedModel,
                )['icon'],
                size: 20,
                color: const Color(0xFF1A1A2E),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedModel,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Color(0xFF1A1A2E),
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: const Color(0xFF1A1A2E),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: const AppSidebar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child:
                    _showWelcomeMessage
                        ? _buildWelcomeMessage()
                        : _buildChatMessages(),
              ),
              _buildChatInput(),
            ],
          ),
          if (_showModelSelector) _buildModelSelector(),
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

  Widget _buildModelSelector() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Base AI Models',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            ..._aiModels.map(
              (model) => ModelSelector(
                name: model['name'],
                description: model['description'],
                cost: model['cost'],
                icon: model['icon'],
                isSelected: _selectedModel == model['name'],
                onTap: () => _handleModelSelect(model['name']),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
