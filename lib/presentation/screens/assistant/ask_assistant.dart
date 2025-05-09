import 'package:amd_chat_ai/service/chat_service.dart';
import 'package:amd_chat_ai/service/prompt_service.dart';
import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';

class AskAssistantScreen extends StatefulWidget {
  const AskAssistantScreen({super.key});

  @override
  State<AskAssistantScreen> createState() => _AskAssistantScreenState();
}

class _AskAssistantScreenState extends State<AskAssistantScreen> {
  final PromptService _promptService = PromptService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];

  // Chat service
  final ChatAIService _chatService = ChatAIService();
  String? _currentConversationId;
  bool _isWaitingForResponse = false; // For waiting for chat API response

  // Assistant information
  dynamic _assistant;
  String _kbAssistantId =
      'cc3748ba-91b0-43b9-a6ce-1a7d4e59fd80'; // Default ID, will be updated from args if available

  List<String> _prompts = []; // List to store fetched prompts
  List<String> _promptContents = []; // List to store fetched prompts
  bool _showPromptList = false; // Flag to show/hide the prompt list
  bool _isFetchingPrompts =
      false; // Flag to indicate if prompts are being fetched

  // Keyboard visibility handling
  void _onFocusChange() {
    // No longer needed to track keyboard visibility
  }

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
      }

      // Extract assistant and assistantId if available
      if (args['assistant'] != null) {
        _assistant = args['assistant'];
        // Try to get the assistant ID from the assistant object
        if (_assistant != null && _assistant.id != null) {
          _kbAssistantId = _assistant.id;
        }
        // If explicitly provided, use that instead
        if (args['assistantId'] != null) {
          _kbAssistantId = args['assistantId'];
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Register listener for keyboard visibility
    _messageFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
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

  Future<void> _handleSendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final message = _messageController.text;
      final timestamp = DateTime.now();

      // Add user message to UI immediately
      setState(() {
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
        // Create placeholder for assistant response
        int assistantMessageIndex = -1;

        // Start streaming message
        final stream = _chatService.sendMessageStream(
          content: message,
          conversationId: _currentConversationId,
          kbAssistantId: _kbAssistantId,
        );

        bool hasError = false;

        await for (final chunk in stream) {
          if (chunk['type'] == 'error') {
            // If streaming fails, use non-streaming as fallback
            hasError = true;
            debugPrint('Streaming failed, trying non-streaming fallback');
            break;
          }

          // Store conversation ID if this is a new conversation
          if (_currentConversationId == null &&
              chunk['conversationId'] != null &&
              chunk['conversationId'].toString().isNotEmpty) {
            setState(() {
              _currentConversationId = chunk['conversationId'];
            });
            debugPrint(
              'New conversation created with ID: $_currentConversationId',
            );
          }

          if (chunk['type'] == 'chunk') {
            // For the first chunk, add a new message
            if (assistantMessageIndex == -1) {
              setState(() {
                // Add initial message
                _messages.add({
                  'message': chunk['content'] ?? '',
                  'type': MessageType.assistant,
                  'timestamp': DateTime.now(),
                });
                assistantMessageIndex = _messages.length - 1;
                _isWaitingForResponse = false; // Remove the loading indicator
              });
            } else {
              // Update existing message with accumulated content
              setState(() {
                _messages[assistantMessageIndex]['message'] =
                    chunk['accumulatedContent'] ?? '';
              });
            }
          } else if (chunk['type'] == 'complete') {
            // Final message received
            setState(() {
              if (assistantMessageIndex != -1) {
                _messages[assistantMessageIndex]['message'] =
                    chunk['content'] ?? '';
              } else {
                // In case we somehow missed adding the message earlier
                _messages.add({
                  'message': chunk['content'] ?? '',
                  'type': MessageType.assistant,
                  'timestamp': DateTime.now(),
                });
              }
              _isWaitingForResponse = false;
            });
          }
        }

        // If streaming failed, try non-streaming fallback
        if (hasError) {
          final response = await _chatService.sendMessageNonStreaming(
            content: message,
            conversationId: _currentConversationId,
            kbAssistantId: _kbAssistantId,
          );

          if (response['type'] == 'error') {
            // Handle error from non-streaming method
            if (mounted) {
              setState(() {
                _isWaitingForResponse = false;
                _messages.add({
                  'message': 'Error: ${response['error']}',
                  'type': MessageType.assistant,
                  'timestamp': DateTime.now(),
                });
              });
            }
          } else {
            // Store conversation ID if this is a new conversation
            if (_currentConversationId == null &&
                response['conversationId'] != null &&
                response['conversationId'].toString().isNotEmpty) {
              _currentConversationId = response['conversationId'];
              debugPrint(
                'New conversation created with ID: $_currentConversationId',
              );
            }

            // Add the response message
            if (mounted) {
              setState(() {
                _isWaitingForResponse = false;
                _messages.add({
                  'message': response['content'] ?? '',
                  'type': MessageType.assistant,
                  'timestamp': DateTime.now(),
                });
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error in message stream: $e');
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

  // Create a new conversation
  void _createNewConversation() {
    setState(() {
      _currentConversationId = null;
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      child: BaseScreen(
        title: 'Assistant Preview',
        body: Column(
          children: [
            // Instruction header - always visible
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.blue.shade100, width: 1),
                ),
              ),
              child: Text(
                'Preview the assistant\'s responses in a chat interface.',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Existing chat content
            Expanded(child: _buildChatMessages()),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages() {
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
            // Input with buttons
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.send,
                          // Reduce rebuilds when typing
                          enableSuggestions: false,
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
                            // Only fetch prompts if the text starts with '/'
                            if (value.startsWith('/')) {
                              // Remove the '/' prefix for the search query
                              _fetchPrompts(value.substring(1));
                            } else {
                              // Hide prompt list if text doesn't start with '/'
                              setState(() {
                                _showPromptList = false;
                              });
                            }
                          },
                          onSubmitted: (_) async => await _handleSendMessage(),
                        ),
                      ),
                      // New chat button
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: Colors.grey,
                        iconSize: 20,
                        onPressed: _createNewConversation,
                        tooltip: 'Start a new conversation',
                      ),
                    ],
                  ),
                  // Prompt list (when active)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child:
                        _showPromptList
                            ? Container(
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
                                          final promptTitle = _prompts[index];
                                          final promptContent =
                                              _promptContents[index];
                                          return ListTile(
                                            title: Text(promptTitle),
                                            onTap: () {
                                              setState(() {
                                                _showPromptList = false;
                                              });
                                              _showPromptSelectionModal(
                                                promptTitle,
                                                promptContent,
                                              );
                                            },
                                          );
                                        },
                                      ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Bottom row with send button only
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Send button
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
                const SizedBox(width: 8),
              ],
            ),
          ],
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
}
