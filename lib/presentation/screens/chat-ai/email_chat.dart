import 'package:amd_chat_ai/model/conversation.dart';
import 'package:amd_chat_ai/model/conversation_message.dart';
import 'package:amd_chat_ai/model/assistant.dart';
import 'package:amd_chat_ai/model/email_request.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/chat-ai/conversation_history_modal.dart';
import 'package:amd_chat_ai/service/chat_service.dart';
import 'package:amd_chat_ai/service/prompt_service.dart';
import 'package:amd_chat_ai/service/assistant_service.dart';
import 'package:amd_chat_ai/service/user_service.dart';
import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:flutter/services.dart';

class EmailChatScreen extends StatefulWidget {
  const EmailChatScreen({super.key});

  @override
  State<EmailChatScreen> createState() => _EmailChatScreenState();
}

class _EmailChatScreenState extends State<EmailChatScreen> {
  final PromptService _promptService = PromptService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];
  bool _showWelcomeMessage = true;

  // Conversation history
  final ChatAIService _chatService = ChatAIService();
  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false; // For loading conversation history
  bool _isWaitingForResponse = false; // For waiting for chat API response
  String? _currentConversationId;

  List<String> _prompts = []; // List to store fetched prompts
  List<String> _promptContents = []; // List to store fetched prompts
  bool _showPromptList = false; // Flag to show/hide the prompt list
  bool _isFetchingPrompts =
      false; // Flag to indicate if prompts are being fetched

  final ScrollController _scrollController = ScrollController();
  String _selectedOption = 'Response Email'; 



  // Keyboard visibility handling
  bool _isKeyboardVisible = false;

  // Flag to indicate if we're currently selecting an assistant
  bool _isSelectingAssistant = false;
  // ID of the assistant we're trying to select
  String? _pendingAssistantId;

  final TextEditingController _mainIdeaController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  // Predefined AI models
  final List<Map<String, dynamic>> _aiModels = [
    {
      'model': 'dify',
      'id': 'gpt-4o',
      'name': 'GPT-4o',
      'description':
          'OpenAI\'s latest flagship model (2024), optimized for multimodal input (text, image, audio) with faster response and lower cost.',
      'selected': true,
    },
    {
      'model': 'dify',
      'id': 'gpt-4o-mini',
      'name': 'GPT-4o mini',
      'description':
          'Lightweight version of GPT-4o offering faster performance and lower latency for lightweight tasks.',
      'selected': false,
    },
    {
      'model': 'dify',
      'id': 'claude-3-haiku-20240307',
      'name': 'Claude 3 Haiku',
      'description':
          'Anthropic\'s smallest Claude 3 model, designed for high-speed, cost-efficient tasks with solid language understanding.',
      'selected': false,
    },
    {
      'model': 'dify',
      'id': 'claude-3-5-sonnet-20240620',
      'name': 'Claude 3.5 Sonnet',
      'description':
          'Next-gen Claude model by Anthropic, balancing performance and reasoning with advanced capabilities released mid-2024.',
      'selected': false,
    },
    {
      'model': 'dify',
      'id': 'gemini-1.5-flash-latest',
      'name': 'Gemini 1.5 Flash',
      'description':
          'Google DeepMind\'s optimized model for speed, ideal for high-throughput applications with reduced cost.',
      'selected': false,
    },
    {
      'model': 'dify',
      'id': 'gemini-1.5-pro-latest',
      'name': 'Gemini 1.5 Pro',
      'description':
          'Google\'s most powerful Gemini model, supporting long-context understanding and multimodal inputs.',
      'selected': false,
    },
  ];

  // Custom assistants from API
  final AssistantService _assistantService = AssistantService();
  List<Assistant> _customAssistants = [];
  bool _isLoadingAssistants = false;

  // Token usage
  final UserService _userService = UserService();
  int _tokenCount = 0;
  bool _isUnlimited = false;
  bool _isLoadingTokens = true;

  // Get the selected model ID
  String get _selectedModel {
    // Check if any predefined model is selected
    final selectedPredefined = _aiModels.firstWhere(
      (model) => model['selected'] == true,
      orElse: () => {'id': ''},
    );

    if (selectedPredefined['id'].isNotEmpty) {
      return selectedPredefined['id'];
    }

    // Check if any custom assistant is selected
    final selectedCustom =
        _customAssistants
            .where((assistant) => assistant.isSelected == true)
            .toList();

    if (selectedCustom.isNotEmpty) {
      return selectedCustom.first.id;
    }

    // Default to first predefined model if nothing is selected
    return _aiModels.first['id'];
  }

  // Get the selected model name for display
  String get _selectedModelName {
    // If we're selecting an assistant, show loading state
    if (_isSelectingAssistant) {
      return 'Loading...';
    }

    // If we have a pending assistant ID, try to find it in the custom assistants list
    if (_pendingAssistantId != null) {
      final pendingAssistant = _customAssistants.firstWhere(
        (assistant) => assistant.id == _pendingAssistantId,
        orElse:
            () => Assistant(
              id: '',
              assistantName: '',
              description: '',
              instructions: '',
              userId: '',
              isDefault: false,
              isFavorite: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              permissions: [],
            ),
      );

      if (pendingAssistant.id.isNotEmpty) {
        return pendingAssistant.assistantName;
      }

      return 'Loading...';
    }

    // Check if any custom assistant is selected (priority over predefined models)
    final selectedCustom =
        _customAssistants
            .where((assistant) => assistant.isSelected == true)
            .toList();

    if (selectedCustom.isNotEmpty) {
      return selectedCustom.first.assistantName;
    }

    // Only check predefined models if no custom assistant is selected
    final selectedPredefined = _aiModels.firstWhere(
      (model) => model['selected'] == true,
      orElse: () => {'name': ''},
    );

    if (selectedPredefined['name'].isNotEmpty) {
      return selectedPredefined['name'];
    }

    // Default to first predefined model if nothing is selected
    return _aiModels.first['name'];
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['showPromptModal'] == true &&
          args['promptTitle'] != null &&
          args['promptDescription'] != null) {
        // Delay to ensure the widget is built completely
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPromptSelectionModal(
            args['promptTitle'],
            args['promptDescription'],
          );
        });
      } else if (args['prompt'] != null) {
        _messageController.text = args['prompt'];

        // If sendImmediately flag is true, send the message automatically
        if (args['sendImmediately'] == true) {
          // Use a post-frame callback to ensure the UI is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleSendMessage();
          });
        }
      } else if (args['assistant'] != null) {
        // Handle the assistant passed from AssistantScreen
        final assistant = args['assistant'] as Assistant;

        // Set the pending assistant ID
        setState(() {
          _isSelectingAssistant = true;
          _pendingAssistantId = assistant.id;
        });

        // Wait for assistants to be loaded before selecting
        if (_customAssistants.isEmpty) {
          // Store the assistant to be selected after loading
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _fetchCustomAssistants();
            _selectAssistant(assistant.id);
          });
        } else {
          _selectAssistant(assistant.id);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Load data in parallel for faster startup
    Future.wait([_fetchCustomAssistants(), _fetchTokenUsage()]);

    // Register listener for keyboard visibility
    _messageFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isKeyboardVisible = _messageFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    _mainIdeaController.dispose();
    _actionController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _senderController.dispose();
    _receiverController.dispose();
    _languageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
      _showPromptList = true; // Always show prompt list when fetching
    });

    final response = await _promptService.getPrompts(searchQuery: query);
    if (response != null) {
      setState(() {
        _prompts = response.items.map((prompt) => prompt.title).toList();
        _promptContents =
            response.items.map((prompt) => prompt.content).toList();
        _showPromptList = _prompts.isNotEmpty;
        _isFetchingPrompts = false;
      });
    } else {
      setState(() {
        _prompts = [];
        _promptContents = [];
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
        assistantId: _selectedModel,
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

  String changeFormatSuggestReplyIdeas(String input) {
    String formatted = input
        .substring(1, input.length - 1) // Remove the square brackets
        .split(',') // Split by comma
        .map((e) => e.trim()) // Trim whitespace
        .join(',\n'); // Join with a newline after each comma

    return formatted;
  }

  Future<void> _handleSendMessage() async {
    _messageController.text =
        'Main idea : ${_mainIdeaController.text}\n'
        'Action : ${_actionController.text}\n'
        'Email : ${_emailController.text}\n'
        'Subject : ${_subjectController.text}\n'
        'Sender : ${_senderController.text}\n'
        'Receiver : ${_receiverController.text}\n'
        'Language : ${_languageController.text}';

    final mainIdea = _mainIdeaController.text.trim();
    final action = _actionController.text.trim();
    final email = _emailController.text.trim();

    if (mainIdea.isEmpty || action.isEmpty || email.isEmpty) {
      // Show an error if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

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

      var emailRequest = {
        'mainIdea': mainIdea.toString(),
        'action': action,
        'email': email,
        'metadata': {
          'subject': _subjectController.text,
          'sender': _senderController.text,
          'receiver': _receiverController.text,
          'language': _languageController.text,
        },
      };

      print('Email Request: $emailRequest');

      try {
        final response =
            _selectedOption == 'Response Email'
                ? await _chatService.sendResponseMail(
                  assistantId: _selectedModel,
                  conversationId: _currentConversationId,
                  emailRequest: EmailRequest.fromJson(emailRequest),
                )
                : await _chatService.suggestReplyIdeas(
          assistantId: _selectedModel,
          conversationId: _currentConversationId,
          emailRequest: EmailRequest.fromJson(emailRequest),
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

          // Update token count if available in response
          if (response.data['remainingUsage'] != null) {
            setState(() {
              _tokenCount = response.data['remainingUsage'];
            });
          }

          

          // Add AI response to UI
          if (mounted) {
            setState(() {
              _isWaitingForResponse = false;
              _messages.add({
                'message':
                    _selectedOption == "Response Email"
                        ? response.data['email'] ?? 'No response from assistant'
                        : changeFormatSuggestReplyIdeas(
                          response.data['ideas'].toString(),
                        ),
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

  // Fetch custom assistants from API
  Future<void> _fetchCustomAssistants() async {
    setState(() {
      _isLoadingAssistants = true;
    });

    try {
      final response = await _assistantService.getAssistants(
        limit: 50, // Get a reasonable number of assistants
      );

      if (response != null) {
        setState(() {
          // Add isSelected field to each assistant and set model to 'knowledge-base'
          _customAssistants =
              response.items.map((assistant) {
                // If we have a pending assistant ID, select it
                assistant.isSelected =
                    _pendingAssistantId != null &&
                    assistant.id == _pendingAssistantId;
                assistant.model =
                    'knowledge-base'; // Set model to knowledge-base for all assistants
                return assistant;
              }).toList();
          _isLoadingAssistants = false;

          // If we had a pending assistant selection, clear the flags
          if (_pendingAssistantId != null) {
            _isSelectingAssistant = false;
            _pendingAssistantId = null;
          }
        });
      } else {
        setState(() {
          _customAssistants = [];
          _isLoadingAssistants = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching custom assistants: $e');
      setState(() {
        _customAssistants = [];
        _isLoadingAssistants = false;
      });
    }
  }

  Future<void> _fetchTokenUsage() async {
    try {
      final tokenUsage = await _userService.getTokenUsage();
      if (tokenUsage != null) {
        setState(() {
          _isUnlimited = tokenUsage['unlimited'] ?? false;
          _tokenCount = tokenUsage['availableTokens'] ?? 0;
          _isLoadingTokens = false;
        });
      } else {
        setState(() {
          _isLoadingTokens = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching token usage: $e');
      setState(() {
        _isLoadingTokens = false;
      });
    }
  }

  void _changeAIModel(String modelId, {bool isCustomAssistant = false}) {
    setState(() {
      // Deselect all predefined models
      for (var model in _aiModels) {
        model['selected'] = !isCustomAssistant && model['id'] == modelId;
      }

      // Deselect all custom assistants
      for (var assistant in _customAssistants) {
        assistant.isSelected = isCustomAssistant && assistant.id == modelId;
      }
    });
    Navigator.of(context).pop();
  }

  void _showModelSelectionDialog() {
    // Model provider logos/icons
    final Map<String, IconData> modelIcons = {
      'gpt': Icons.auto_awesome,
      'claude': Icons.psychology,
      'gemini': Icons.brightness_auto,
      'custom': Icons.assistant,
    };

    // Get icon based on model ID
    IconData getModelIcon(String modelId) {
      if (modelId.startsWith('gpt-')) return modelIcons['gpt']!;
      if (modelId.startsWith('claude-')) return modelIcons['claude']!;
      if (modelId.startsWith('gemini-')) return modelIcons['gemini']!;
      return modelIcons['custom']!;
    }

    // Get color based on model ID
    Color getModelColor(String modelId) {
      if (modelId.startsWith('gpt-')) return Colors.green.shade700;
      if (modelId.startsWith('claude-')) return Colors.purple.shade700;
      if (modelId.startsWith('gemini-')) return Colors.blue.shade700;
      return Colors.orange.shade700;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Select AI Model",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Dialog content in a scrollview
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Predefined models section
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8,
                              top: 16,
                              bottom: 8,
                            ),
                            child: Text(
                              "Popular Models",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          // Predefined models grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio:
                                      0.9, // Reduced from 1.3 to allow for longer text
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing:
                                      12, // Increased from 8 to give more vertical space
                                ),
                            itemCount: _aiModels.length,
                            itemBuilder: (context, index) {
                              final model = _aiModels[index];
                              final isSelected = model['selected'];
                              final modelColor = getModelColor(model['id']);

                              return InkWell(
                                onTap: () => _changeAIModel(model['id']),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? modelColor
                                              : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    color: modelColor.withAlpha(25),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header with icon and check
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: modelColor.withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              getModelIcon(model['id']),
                                              size: 16,
                                              color: modelColor,
                                            ),
                                          ),
                                          if (isSelected)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: modelColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Model name
                                      Text(
                                        model['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color:
                                              isSelected
                                                  ? modelColor
                                                  : Colors.grey.shade800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Description with scrollable text
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            model['description'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Custom assistants section
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8,
                              top: 24,
                              bottom: 8,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "Custom Assistants",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                if (_customAssistants.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: _fetchCustomAssistants,
                                    icon: const Icon(Icons.refresh, size: 14),
                                    label: const Text(
                                      "Refresh",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Loading indicator for custom assistants
                          if (_isLoadingAssistants)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Loading assistants...",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_customAssistants.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assistant_outlined,
                                      size: 36,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No custom assistants available",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _customAssistants.length,
                              itemBuilder: (context, index) {
                                final assistant = _customAssistants[index];
                                final isSelected =
                                    assistant.isSelected ?? false;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.orange.shade700
                                              : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    color:
                                        isSelected
                                            ? Colors.orange.shade50
                                            : Colors.white,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap:
                                        () => _changeAIModel(
                                          assistant.id,
                                          isCustomAssistant: true,
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withAlpha(
                                                25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.assistant,
                                              size: 20,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        assistant.assistantName,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    if (assistant.isFavorite)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 4,
                                                            ),
                                                        child: Icon(
                                                          Icons.star,
                                                          size: 16,
                                                          color:
                                                              Colors
                                                                  .amber
                                                                  .shade700,
                                                        ),
                                                      ),
                                                    if (isSelected)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 4,
                                                            ),
                                                        child: Icon(
                                                          Icons.check_circle,
                                                          size: 16,
                                                          color:
                                                              Colors
                                                                  .orange
                                                                  .shade700,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                // Limit description to 3 lines
                                                Text(
                                                  assistant.description,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    height: 1.3,
                                                  ),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: BaseScreen(
        title: 'Chat AI',
        isChatScreen: true,
        body: Column(
          children: [
            // Model selector and conversation indicator
            // Only show this when keyboard is not visible to save layout computation
            if (!_isKeyboardVisible)
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
                            Icon(
                              Icons.chat,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          backgroundColor: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon based on model type
                            Icon(
                              _selectedModel.startsWith('gpt-')
                                  ? Icons.auto_awesome
                                  : _selectedModel.startsWith('claude-')
                                  ? Icons.psychology
                                  : _selectedModel.startsWith('gemini-')
                                  ? Icons.brightness_auto
                                  : Icons.assistant,
                              size: 16,
                              color:
                                  _selectedModel.startsWith('gpt-')
                                      ? Colors.green.shade700
                                      : _selectedModel.startsWith('claude-')
                                      ? Colors.purple.shade700
                                      : _selectedModel.startsWith('gemini-')
                                      ? Colors.blue.shade700
                                      : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.36,
                              ),
                              child: Text(
                                _selectedModelName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade700,
                              size: 18,
                            ),
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
                'Hi, email support!',
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
          'I\'m Jarvis, your personal assistant for email.',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Don\'t know what to say? Use a prompt!',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());


    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // Add +1 to itemCount if we're waiting for a response to show the loading indicator
      itemCount: _messages.length + (_isWaitingForResponse ? 1 : 0),
      // Use cacheExtent to keep more items in memory for smooth scrolling
      cacheExtent: 1000,
      // Reduce rebuilds by providing explicit key for each item
      key: ValueKey<int>(_messages.length),
      // Use addAutomaticKeepAlives to keep items alive when scrolled off screen
      addAutomaticKeepAlives: true,
      // Use addRepaintBoundaries to reduce unnecessary repaints
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        // If we're at the last item and waiting for a response, show a loading indicator
        if (index == _messages.length && _isWaitingForResponse) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Column(
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

        // Otherwise show the message with a unique key
        final message = _messages[index];
        return RepaintBoundary(
          child: ChatMessage(
            key: ValueKey('msg_$index'),
            message: message['message'],
            type: message['type'],
            timestamp: message['timestamp'],
            showAvatar:
                index == 0 || _messages[index - 1]['type'] != message['type'],
          ),
        );
      },
    );
  }

  Future<void> _handleSendFields() async {
    final mainIdea = _mainIdeaController.text.trim();
    final action = _actionController.text.trim();
    final email = _emailController.text.trim();

    if (mainIdea.isEmpty || action.isEmpty || email.isEmpty) {
      // Show an error if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Handle sending the fields (e.g., API call or processing)
    print('Main Idea: $mainIdea');
    print('Action: $action');
    print('Email: $email');

    // Clear the fields after sending
    _mainIdeaController.clear();
    _actionController.clear();
    _emailController.clear();

    // Show a success message
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fields sent successfully')));
  }

Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 200, // Set the desired height here
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main Idea Input
                TextField(
                  controller: _mainIdeaController,
                  decoration: const InputDecoration(
                    labelText: 'Main Idea',
                    hintText: 'Enter the main idea...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Action Input
                TextField(
                  controller: _actionController,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    hintText: 'Enter the action...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Email Input
                TextField(
                  controller: _emailController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Email Content',
                    hintText: 'Enter the email content...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Subject Input
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Enter the subject...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Sender Input
                TextField(
                  controller: _senderController,
                  decoration: const InputDecoration(
                    labelText: 'Sender',
                    hintText: 'Enter the sender...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Receiver Input
                TextField(
                  controller: _receiverController,
                  decoration: const InputDecoration(
                    labelText: 'Receiver',
                    hintText: 'Enter the receiver...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Language Input
                TextField(
                  controller: _languageController,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    hintText: 'Enter the language...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Send Button and Dropdown
                Row(
                  children: [
                    // Dropdown for selecting options
                    DropdownButton<String>(
                      value: _selectedOption,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedOption = newValue; // Update state
                          });
                        }
                      },
                      items:
                          <String>[
                            'Response Email',
                            'Suggest Reply',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await _handleSendMessage();
                      },
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
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showPromptSelectionModal(String promptTitle, String promptDescription) {
    // Create controller once and cache common widgets
    final TextEditingController inputController = TextEditingController();

    // Only log in debug mode
    debugPrint(
      'Showing prompt modal - Title: $promptTitle, Content: $promptDescription',
    );

    // Show a simpler dialog that is guaranteed to close properly
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with precalculated gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_objects_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          promptTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prompt section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prompt',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(dialogContext).size.height *
                                    0.2,
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  promptDescription,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Input section - make this section as efficient as possible
                      const Text(
                        'Your Input',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: inputController,
                        decoration: InputDecoration(
                          hintText: 'Add details to your prompt...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              final userInput = inputController.text.trim();
                              final formattedPrompt =
                                  '#About Yourself: $promptDescription + \nMy Problem: $userInput';
                              Navigator.pop(dialogContext);

                              // Use efficient management for text controller
                              _messageController.value = TextEditingValue(
                                text: formattedPrompt,
                                selection: TextSelection.collapsed(
                                  offset: formattedPrompt.length,
                                ),
                              );
                              _handleSendMessage();
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send, size: 16),
                                SizedBox(width: 8),
                                Text('Send'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to select an assistant by ID
  void _selectAssistant(String assistantId) {
    // First find if the assistant exists in our list
    final assistantExists = _customAssistants.any((a) => a.id == assistantId);

    setState(() {
      if (assistantExists) {
        // Deselect all predefined models
        for (var model in _aiModels) {
          model['selected'] = false;
        }

        // Find and select the custom assistant
        for (var assistant in _customAssistants) {
          assistant.isSelected = assistant.id == assistantId;
        }

        // Clear selection flags
        _isSelectingAssistant = false;
        _pendingAssistantId = null;
      } else {
        // If assistant not found yet, keep the pending ID but stop loading indication
        _isSelectingAssistant = false;
        _pendingAssistantId = assistantId;
      }
    });
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with animation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.red.shade400,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Exit Application',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    'Are you sure you want to exit the app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel button
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),

                      // Exit button
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    return result ?? false;
  }
}
