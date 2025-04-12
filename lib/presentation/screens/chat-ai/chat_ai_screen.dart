import 'package:amd_chat_ai/model/conversation.dart';
import 'package:amd_chat_ai/model/conversation_message.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/chat-ai/conversation_history_modal.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/chat-ai/prompt_template.dart';
import 'package:amd_chat_ai/service/chat_service.dart';
import 'package:amd_chat_ai/service/prompt_service.dart';
import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final PromptService _promptService = PromptService();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _showWelcomeMessage = true;

  // Conversation history
  final ChatAIService _chatService = ChatAIService();
  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false; // For loading conversation history
  bool _isWaitingForResponse = false; // For waiting for chat API response
  String? _currentConversationId;

  List<String> _prompts = []; // List to store fetched prompts
  bool _showPromptList = false; // Flag to show/hide the prompt list
  bool _isFetchingPrompts =
      false; // Flag to indicate if prompts are being fetched
  String _searchQuery = ''; // Current search query


  
  final List<Map<String, dynamic>> _aiModels = [
    {
      'name': 'gpt-4o',
      'selected': true,
      'description': 'Most capable GPT model for complex tasks',
      'tokens': '128K context',
      'speed': 'Fast',
    },
    {
      'name': 'gpt-4o-mini',
      'selected': false,
      'description': 'Efficient GPT model for everyday tasks',
      'tokens': '128K context',
      'speed': 'Very Fast',
    },
    {
      'name': 'claude-3-haiku-20240307',
      'selected': false,
      'description': 'Fast Claude model for everyday tasks',
      'tokens': '200K context',
      'speed': 'Very Fast',
    },
    {
      'name': 'claude-3-5-sonnet-20240620',
      'selected': false,
      'description': 'Advanced Claude model for complex tasks',
      'tokens': '200K context',
      'speed': 'Fast',
    },
    {
      'name': 'gemini-1.5-flash-latest',
      'selected': false,
      'description': 'Fast Gemini model for everyday tasks',
      'tokens': '1M context',
      'speed': 'Very Fast',
    },
    {
      'name': 'gemini-1.5-pro-latest',
      'selected': false,
      'description': 'Advanced Gemini model for complex tasks',
      'tokens': '1M context',
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

  // @override
  // void initState() {
  //   super.initState();
  //   final args =
  //       ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  //   if (args != null && args['prompt'] != null) {
  //     _messageController.text =
  //         args['prompt']; // Pre-fill the input field with the prompt
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['prompt'] != null) {
      _messageController.text =
          args['prompt']; // Pre-fill the input field with the prompt
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrompts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _prompts = [];
        _showPromptList = false;
      });
      return;
    }

    setState(() {
      _isFetchingPrompts = true;
    });

    final response = await _promptService.getPrompts(searchQuery: query);
    if (response != null) {
      setState(() {
        _prompts = response.items.map((prompt) => prompt.title).toList();
        _showPromptList = _prompts.isNotEmpty;
        _isFetchingPrompts = false;
      });
    } else {
      setState(() {
        _prompts = [];
        _showPromptList = false;
        _isFetchingPrompts = false;
      });
    }
  }


  // Show conversation history modal
  void _showConversationHistoryModal() async {
    // Set loading state
    setState(() {
      _isLoadingConversations = true;
    });

    // Fetch conversations first
    try {
      final response = await _chatService.fetchConversations();

      if (response != null && response.statusCode == 200) {
        final conversationResponse = ConversationResponse.fromJson(
          response.data,
        );
        setState(() {
          _conversations = conversationResponse.items;
          _isLoadingConversations = false;
        });

        // Now show the modal with the loaded conversations
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return ConversationHistoryModal(
                conversations: _conversations,
                isLoading: false, // We've already loaded the conversations
                onConversationSelected: (conversationId) {
                  _loadConversation(conversationId);
                },
              );
            },
          );
        }
      } else {
        setState(() {
          _conversations = [];
          _isLoadingConversations = false;
        });

        // Show modal with empty conversations
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return ConversationHistoryModal(
                conversations: [],
                isLoading: false,
                onConversationSelected: (_) {}, // Empty callback
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching conversation history: $e');
      setState(() {
        _conversations = [];
        _isLoadingConversations = false;
      });

      // Show error in modal
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return ConversationHistoryModal(
              conversations: [],
              isLoading: false,
              onConversationSelected: (_) {}, // Empty callback
            );
          },
        );
      }
    }
  }

  // Load a specific conversation
  Future<void> _loadConversation(String conversationId) async {
    debugPrint('Loading conversation: $conversationId');
    setState(() {
      _currentConversationId = conversationId;
      _messages.clear();
      _showWelcomeMessage = false;
      _isLoadingConversations = true;
    });

    // Add a timeout to prevent loading forever
    bool timeoutOccurred = false;
    Future.delayed(const Duration(seconds: 10), () {
      if (_isLoadingConversations &&
          mounted &&
          _currentConversationId == conversationId) {
        debugPrint(
          'Timeout occurred while loading conversation: $conversationId',
        );
        setState(() {
          _isLoadingConversations = false;
          timeoutOccurred = true;
          _messages.add({
            'message': 'Loading conversation timed out. Please try again.',
            'type': MessageType.assistant,
            'timestamp': DateTime.now(),
          });
        });
      }
    });

    try {
      final response = await _chatService.fetchConversationHistory(
        conversationId: conversationId,
      );

      // If timeout already occurred, don't update state
      if (timeoutOccurred) return;

      if (response != null && response.statusCode == 200) {
        final messagesResponse = ConversationMessagesResponse.fromJson(
          response.data,
        );
        if (mounted) {
          setState(() {
            _isLoadingConversations = false;

            // Add messages to the chat
            for (final message in messagesResponse.items) {
              // Add user message first
              _messages.add({
                'message': message.query,
                'type': MessageType.user,
                'timestamp': message.createdAt,
              });

              // Then add assistant response
              _messages.add({
                'message': message.answer,
                'type': MessageType.assistant,
                'timestamp': message.createdAt,
              });
            }

            // If no messages were loaded, show a message
            if (messagesResponse.items.isEmpty) {
              _messages.add({
                'message': 'No messages found in this conversation.',
                'type': MessageType.assistant,
                'timestamp': DateTime.now(),
              });
            }
          });
        }
      } else {
        if (mounted && !timeoutOccurred) {
          setState(() {
            _isLoadingConversations = false;
            _messages.add({
              'message': 'Failed to load conversation messages',
              'type': MessageType.assistant,
              'timestamp': DateTime.now(),
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading conversation messages: $e');
      if (mounted && !timeoutOccurred) {
        setState(() {
          _isLoadingConversations = false;
          _messages.add({
            'message': 'Error loading conversation: $e',
            'type': MessageType.assistant,
            'timestamp': DateTime.now(),
          });
        });
      }
    }
  }

  // Create a new conversation
  void _createNewConversation() {
    setState(() {
      _currentConversationId = null;
      _messages.clear();
      _showWelcomeMessage = true;
      _isLoadingConversations = false; // Reset loading state
    });
  }

  Future<void> _handleSendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final message = _messageController.text;
      final timestamp = DateTime.now();

      // Add user message to UI immediately
      setState(() {
        _showWelcomeMessage = false;
        _messages.add({
          'message': message,
          'type': MessageType.user,
          'timestamp': timestamp,
        });
        // Show loading indicator for chat response
        _isWaitingForResponse = true;
      });

      // Clear input field immediately for better UX
      _messageController.clear();

      try {
        // Send message to API
        final response = await _chatService.sendMessage(
          content: message,
          assistantId: _selectedModel,
          conversationId: _currentConversationId,
        );

        if (response != null &&
            (response.statusCode == 200 || response.statusCode == 201)) {
          // If this was a new conversation, save the conversation ID
          if (_currentConversationId == null &&
              response.data['conversationId'] != null) {
            _currentConversationId = response.data['conversationId'];
            debugPrint(
              'New conversation created with ID: $_currentConversationId',
            );
          }

          // Add AI response to UI
          if (mounted) {
            setState(() {
              _isWaitingForResponse = false;
              _messages.add({
                'message':
                    response.data['message'] ?? 'No response from assistant',
                'type': MessageType.assistant,
                'timestamp': DateTime.now(),
              });
            });
          }
        } else {
          // Handle error
          if (mounted) {
            setState(() {
              _isWaitingForResponse = false;
              _messages.add({
                'message': 'Failed to send message. Please try again.',
                'type': MessageType.assistant,
                'timestamp': DateTime.now(),
              });
            });
          }
        }
      } catch (e) {
        debugPrint('Error sending message: $e');
        if (mounted) {
          setState(() {
            _isWaitingForResponse = false;
            _messages.add({
              'message': 'Error: $e',
              'type': MessageType.assistant,
              'timestamp': DateTime.now(),
            });
          });
        }
      }
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
                        Flexible(
                          child: Text(
                            model['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                                    ? Colors.blue.withAlpha(25)
                                    : Colors.grey.withAlpha(25),
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
                    selectedTileColor: Colors.blue.withAlpha(13),
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
          // Model selector and conversation indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Current conversation indicator
                if (_currentConversationId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'In conversation',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Model selector
                Center(
                  child: TextButton(
                    onPressed: _showModelSelectionDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.4,
                          ),
                          child: Text(
                            _selectedModel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👋', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Hi, good evening!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                overflow: TextOverflow.ellipsis,
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
    // Only show loading indicator if we're loading a conversation history and not showing the welcome screen
    if (_isLoadingConversations &&
        !_showWelcomeMessage &&
        _currentConversationId != null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading conversation history...'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // Add +1 to itemCount if we're waiting for a response to show the loading indicator
      itemCount: _messages.length + (_isWaitingForResponse ? 1 : 0),
      itemBuilder: (context, index) {
        // If we're at the last item and waiting for a response, show a loading indicator
        if (index == _messages.length && _isWaitingForResponse) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: const Column(
                children: [
                  SizedBox(height: 8),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(height: 8),
                  Text('Thinking...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        // Otherwise show the message
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText:
                                'Ask me anything, press \'/\' for prompts...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            _searchQuery = value;
                            _fetchPrompts(
                              value,
                            ); // Fetch prompts as the user types
                          },
                          onSubmitted: (_) async => await _handleSendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.schedule),
                        color: Colors.grey,
                        onPressed: _showConversationHistoryModal,
                        tooltip: 'View conversation history',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.grey,
                        onPressed: _createNewConversation,
                        tooltip: 'Start a new conversation',
                      ),
                    ],
                  ),
                  if (_showPromptList)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child:
                          _isFetchingPrompts
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _prompts.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(_prompts[index]),
                                    onTap: () {
                                      setState(() {
                                        _messageController.text =
                                            _prompts[index];
                                        _showPromptList = false;
                                      });
                                    },
                                  );
                                },
                              ),
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
                  onPressed: () async => await _handleSendMessage(),
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
