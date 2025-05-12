import 'package:amd_chat_ai/model/email_request.dart';
import 'package:amd_chat_ai/service/chat_service.dart';
import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class EmailChatScreen extends StatefulWidget {
  const EmailChatScreen({super.key});

  @override
  State<EmailChatScreen> createState() => _EmailChatScreenState();
}

class _EmailChatScreenState extends State<EmailChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _mainIdeaController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  final FocusNode _messageFocusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];
  bool _showWelcomeMessage = true;
  Timer? _adTimer;

  // Chat service
  final ChatAIService _chatService = ChatAIService();
  bool _isWaitingForResponse = false;
  String? _currentConversationId;

  // Keyboard visibility handling
  bool _isKeyboardVisible = false;

  bool _isSuggestingMainIdea = false;
  List<String> _mainIdeaSuggestions = [];

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    _messageController.dispose();
    _mainIdeaController.dispose();
    _actionController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _senderController.dispose();
    _receiverController.dispose();
    _languageController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isKeyboardVisible = _messageFocusNode.hasFocus;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['prompt'] != null) {
      _messageController.text = args['prompt'];

      // If sendImmediately flag is true, send the message automatically
      if (args['sendImmediately'] == true) {
        // Use a post-frame callback to ensure the UI is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleSendMessage();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: BaseScreen(
        title: 'Email Assistant',
        body: SafeArea(
          bottom:
              false, // Don't apply bottom padding since we handle it manually
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate available height for content
              final availableHeight = constraints.maxHeight;

              return Column(
                children: [
                  // Message area with flexible height
                  SizedBox(
                    height:
                        availableHeight *
                        0.4, // 40% of available height for messages
                    child:
                        _showWelcomeMessage
                            ? _buildWelcomeMessage()
                            : _buildChatMessages(),
                  ),

                  // Input area with fixed 60% height that scrolls internally
                  Container(
                    height: availableHeight * 0.6,
                    child: _buildChatInput(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.email_outlined,
                size: 48,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome to Email Assistant',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'I\'ll help you craft professional and effective emails.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber.shade700,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for best results:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTip('Be clear about your main idea'),
                  _buildTip('Specify the desired action'),
                  _buildTip('Provide context in the email content'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 12,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isWaitingForResponse ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isWaitingForResponse) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crafting your email...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        final message = _messages[index];
        return ChatMessage(
          key: ValueKey('msg_$index'),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputField(
              controller: _actionController,
              label: 'Action',
              hint: 'What do you want the recipient to do?',
              icon: Icons.play_arrow,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _emailController,
              label: 'Email Content',
              hint: 'Enter the email content or context...',
              icon: Icons.email_outlined,
              maxLines: 3, // Reduced to save space
              required: true,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _mainIdeaController,
              label: 'Main Idea',
              hint: 'What\'s the key message?',
              icon: Icons.lightbulb_outline,
              required: true,
              suffix:
                  _isSuggestingMainIdea
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : IconButton(
                        icon: const Icon(
                          Icons.tips_and_updates,
                          color: Colors.amber,
                        ),
                        tooltip: 'Suggest Main Idea',
                        onPressed:
                            _isSuggestingMainIdea
                                ? null
                                : _handleSuggestMainIdea,
                      ),
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _subjectController,
              label: 'Subject (optional)',
              hint: 'Email subject',
              icon: Icons.subject,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _senderController,
                    label: 'From (optional)',
                    hint: 'Sender',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _receiverController,
                    label: 'To (optional)',
                    hint: 'Recipient',
                    icon: Icons.person,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _languageController,
              label: 'Language (optional)',
              hint: 'Email language (e.g., English)',
              icon: Icons.language,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleSendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Generate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (suffix != null) ...[const Spacer(), suffix],
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final mainIdea = _mainIdeaController.text.trim();
    final action = _actionController.text.trim();
    final email = _emailController.text.trim();

    if (mainIdea.isEmpty || action.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailRequest = EmailRequest(
      mainIdea: mainIdea,
      action: action,
      email: email,
      metadata: EmailMetadata(
        subject: _subjectController.text.trim(),
        sender: _senderController.text.trim(),
        receiver: _receiverController.text.trim(),
        language: _languageController.text.trim(),
      ),
    );

    setState(() {
      _messages.add({
        'message': 'Main Idea: $mainIdea\nAction: $action\nEmail: $email',
        'type': MessageType.user,
        'timestamp': DateTime.now(),
      });
      _isWaitingForResponse = true;
    });

    // Show dialog immediately with loading
    final dialogKey = GlobalKey<_GeneratedEmailDialogState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GeneratedEmailDialog(key: dialogKey),
    );

    try {
      final response = await _chatService.sendResponseMail(
        emailRequest: emailRequest,
        assistantId: 'gpt-4o-mini',
      );
      if (response != null &&
          response.data != null &&
          response.data['email'] != null) {
        final generatedEmail = response.data['email'] as String;
        setState(() {
          _messages.add({
            'message': generatedEmail,
            'type': MessageType.assistant,
            'timestamp': DateTime.now(),
          });
        });
        dialogKey.currentState?.showResult(generatedEmail);
      } else {
        setState(() {
          _messages.add({
            'message': 'No email generated.',
            'type': MessageType.error,
            'timestamp': DateTime.now(),
          });
        });
        dialogKey.currentState?.showError('No email generated.');
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'message': 'Error: $e',
          'type': MessageType.error,
          'timestamp': DateTime.now(),
        });
      });
      dialogKey.currentState?.showError('Error: $e');
    } finally {
      setState(() {
        _isWaitingForResponse = false;
      });
    }
  }

  Future<void> _handleSuggestMainIdea() async {
    final action = _actionController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final sender = _senderController.text.trim();
    final receiver = _receiverController.text.trim();
    final language = _languageController.text.trim();

    if (action.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Action and Email Content first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSuggestingMainIdea = true;
    });

    try {
      final emailRequest = EmailRequest(
        action: action,
        email: email,
        metadata: EmailMetadata(
          subject: subject,
          sender: sender,
          receiver: receiver,
          language: language,
        ),
      );
      // Use a default assistantId for now (update if needed)
      final response = await _chatService.suggestReplyIdeas(
        emailRequest: emailRequest,
        assistantId: 'gpt-4o-mini',
      );
      if (response != null &&
          response.data != null &&
          response.data['ideas'] is List) {
        final ideas = List<String>.from(response.data['ideas']);
        setState(() {
          _mainIdeaSuggestions = ideas;
        });
        _showMainIdeaSuggestionsModal(ideas);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No suggestions found.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch suggestions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSuggestingMainIdea = false;
      });
    }
  }

  void _showMainIdeaSuggestionsModal(List<String> ideas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tips_and_updates,
                    size: 32,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Suggested Main Ideas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                if (ideas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No suggestions available.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ideas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final idea = ideas[idx];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _mainIdeaController.text = idea;
                            });
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.shade100.withOpacity(
                                    0.15,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.amber.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      idea,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 18),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade900,
                    side: BorderSide(color: Colors.amber.shade200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dialog widget for generated email with loading/result/error
class GeneratedEmailDialog extends StatefulWidget {
  const GeneratedEmailDialog({super.key});

  @override
  State<GeneratedEmailDialog> createState() => _GeneratedEmailDialogState();
}

class _GeneratedEmailDialogState extends State<GeneratedEmailDialog> {
  String? _emailContent;
  String? _error;
  bool _loading = true;

  void showResult(String emailContent) {
    setState(() {
      _emailContent = emailContent;
      _loading = false;
      _error = null;
    });
  }

  void showError(String error) {
    setState(() {
      _error = error;
      _loading = false;
      _emailContent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 40,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Generated Email',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_loading)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Generating your email...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email Content',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(
                    _emailContent ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.copy, size: 20),
                        label: const Text('Copy Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _emailContent!),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard!'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 18,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
