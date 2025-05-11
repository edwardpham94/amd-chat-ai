import 'package:amd_chat_ai/model/datasource.dart';
import 'package:amd_chat_ai/service/knowledge_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/service/prompt_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DatasourceScreen extends StatefulWidget {
  const DatasourceScreen({super.key});

  @override
  State<DatasourceScreen> createState() => _DatasourceScreenState();
}

class _DatasourceScreenState extends State<DatasourceScreen> {
  bool isPrivateSelected = true;
  bool showFavoritesOnly = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _knowledgeId;
  Map<String, dynamic>? _selectedFile;
  String? _selectedSource;
  String? _selectedWebsiteUrl;
  String? _selectedWebsiteName;

  String? _knowledge_unit_name;
  String? _confluence_username;
  String? _confluence_api_token;
  String? _selected_datasource_id_delete;

  final TextEditingController _searchController = TextEditingController();

  // Category filter

  final PromptService _promptService = PromptService();
  final KnowledgeService _knowledgeService = KnowledgeService();
  List<Datasource> _datasources = [];
  int _currentOffset = 0;
  final int _limit = 10;
  bool _hasMoreDatasource = true;
  int _totalDatasources = 0; // Total number of prompts available

  // Focus node to detect when screen regains focus
  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Add a listener to reload data when the screen regains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.addListener(() {
        if (_screenFocusNode.hasFocus) {
          debugPrint('Prompt screen regained focus, refreshing data');
          _loadDatasources(refresh: true);
        }
      });
      // Request focus to trigger the listener
      _screenFocusNode.requestFocus();

      final Map<String, dynamic>? knowledgeData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (knowledgeData != null) {
        setState(() {
          _knowledgeId = knowledgeData['knowledgeId'];
        });
      }
    });

    _checkUserAndLoadPrompts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkUserAndLoadPrompts() async {
    debugPrint('Checking user authentication status');
    final userId = await UserStorage.getUserId();
    final accessToken = await UserStorage.getAccessToken();

    debugPrint('User ID: $userId, Access Token exists: ${accessToken != null}');

    if (userId == null || accessToken == null) {
      debugPrint('User not logged in, navigating to login screen');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    // User is logged in, load prompts
    _loadDatasources();
  }

  void _handleSearchChanged(String value) {
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        debugPrint('Search query: $value');
        _loadDatasources(refresh: true);
      }
    });
  }

  Future<void> _loadDatasources({bool refresh = false}) async {
    debugPrint("Loading prompts - refresh: $refresh");
    if (refresh) {
      setState(() {
        _currentOffset = 0;
        _hasMoreDatasource = true;
        _isLoading = true;
        _hasError = false;
      });
    } else if (!_hasMoreDatasource || _isLoading) {
      return;
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      debugPrint(
        "Making API call to fetch prompts with offset: $_currentOffset",
      );
      final searchQuery = _searchController.text.trim();
      final response = await _knowledgeService.getDatasources(
        offset: _currentOffset,
        limit: 5,
        id: _knowledgeId ?? '',
        q: searchQuery,
      );

      debugPrint("API call completed, response: ${response?.data} items");

      if (response != null) {
        debugPrint(
          "API response received: ${response.meta.total} items, hasNext: ${response.meta.hasNext}",
        );
        setState(() {
          if (refresh || _currentOffset == 0) {
            _datasources = response.data;
          } else {
            _datasources.addAll(response.data);
          }
          _hasMoreDatasource = response.meta.hasNext;
          _currentOffset += response.data.length;
          _totalDatasources =
              response.meta.total > 0
                  ? response.meta.total
                  : _datasources.length;
          debugPrint(
            "Updated offset to: $_currentOffset, total from API: ${response.meta.total}, using: $_totalDatasources",
          );
          _isLoading = false;
        });
        debugPrint("Updated state: ${_datasources.length} total prompts");
      } else {
        debugPrint("API response is null");
        setState(() {
          _hasError = true;
          _isLoading = false;
          _totalDatasources = 0;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _totalDatasources = 0;
      });
      debugPrint('Error loading prompts: $e');
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String itemName,
    String datasourceId,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Delete Dialog",
      barrierColor: Colors.black.withAlpha(50),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Delete Datasource',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message
                    Text(
                      'Are you sure you want to delete "$itemName"? This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Delete Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              var response = await _knowledgeService
                                  .deletDatasource(
                                    knowledgeId: _knowledgeId!,
                                    datasourceId: datasourceId,
                                  );

                              if (response) {
                                _loadDatasources(refresh: true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Datasource deleted'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to delete datasource',
                                    ),
                                  ),
                                );
                              }

                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // Method to handle deleting a prompt
  Future<void> _deletePrompt(String promptId, String promptTitle) async {
    Navigator.of(context).pop(); // Close the confirmation dialog

    try {
      final success = await _promptService.deletePrompt(promptId);

      if (success) {
        setState(() {
          _datasources.removeWhere((p) => p.id == promptId);
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$promptTitle deleted')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete prompt')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting prompt: $e')));
      }
    }
  }

  void _showPromptSelectionModal(String promptTitle, String promptDescription) {
    final TextEditingController inputController = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                          Text(
                            promptDescription,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Input section
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

                            // Navigate to chat screen with the formatted prompt
                            // and a flag to send automatically
                            Navigator.pushNamed(
                              context,
                              '/chat-ai',
                              arguments: {
                                'prompt': formattedPrompt,
                                'sendImmediately': true,
                              },
                            );
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
        );
      },
    );
  }

  Future<void> _handleUploadFileToKnowledge() async {
    if (_selectedFile != null && _selectedFile!['path'] != null) {
      // Upload the local file
      final String filePath = _selectedFile!['path'];
      final responseId = await _knowledgeService.uploadLocalFile(
        filePath: filePath,
      );

      print('Selected file: ${_selectedFile!['name']} - ID: $responseId');

      if (responseId != null) {
        // Import the file to the knowledge
        final success = await _knowledgeService.importDataSourceToKnowledge(
          id: _knowledgeId!,
          fileName: _selectedFile!['name'],
          fileId: responseId,
          type: 'file',
        );

        if (success) {
          setState(() {
            _selectedFile = null;
            _selectedSource = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attached file successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload file. Please try again.'),
            ),
          );
        }
      }
    }

    if (_selectedWebsiteUrl != null) {
      print(
        'Selected website URL: $_selectedWebsiteName $_selectedWebsiteUrl ',
      );
      final success = await _knowledgeService.uploadFromWebsite(
        id: _knowledgeId!,
        webUrl: _selectedWebsiteUrl!,
        unitName: _selectedWebsiteName!,
      );

      if (success) {
        setState(() {
          _selectedWebsiteUrl = null;
          _selectedWebsiteName = null;
          _selectedSource = null;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attached website successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload website. Please try again.'),
          ),
        );
      }
    }

    _loadDatasources(refresh: true);
  }

  Widget _buildSelectedFile() {
    if (_selectedFile == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedFile!['icon'],
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFile!['size'],
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                  });
                },
                color: Colors.grey[400],
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _handleUploadFileToKnowledge();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  void _showFileUploadDialog(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = {
          'name': result.files.single.name,
          'size': '${(result.files.single.size / 1024).toStringAsFixed(2)} KB',
          'progress': 100,
          'icon': Icons.insert_drive_file,
          'path': result.files.single.path, // Add the file path here
        };
        _selectedSource = 'Local files';
      });
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected')));
    }
  }

  void _showWebsiteDialog(BuildContext context) {
    final linkController = TextEditingController();
    final nameController =
        TextEditingController(); // Controller for website name

    bool isValidUrl(String url) {
      try {
        final uri = Uri.parse(url);
        return uri.hasScheme && uri.host.isNotEmpty;
      } catch (e) {
        return false;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isValid = isValidUrl(linkController.text);

            // Add listener to update button state
            linkController.addListener(() {
              setDialogState(() {});
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with avatars
                    CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      radius: 30,
                      child: const Icon(
                        Icons.language_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Website',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Import Link Website',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Website name input field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Website Name',
                        hintText: 'Enter website name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Link input field
                    TextField(
                      controller: linkController,
                      decoration: InputDecoration(
                        labelText: 'Link',
                        hintText: 'Enter website URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste),
                          onPressed: () {
                            // Handle paste functionality
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            isValid
                                ? () {
                                  setState(() {
                                    _selectedSource = 'Website';
                                    _selectedWebsiteUrl = linkController.text;
                                    _selectedWebsiteName = nameController.text;
                                  });
                                  Navigator.pop(context);
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF415DF2),
                          disabledBackgroundColor: Colors.grey[300],
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey[500],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showConfluenceDialog(BuildContext context) {
    final linkController = TextEditingController();
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final apiTokenController = TextEditingController();

    bool isValidUrl(String url) {
      try {
        final uri = Uri.parse(url);
        return uri.hasScheme && uri.host.isNotEmpty;
      } catch (e) {
        return false;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isValid = isValidUrl(linkController.text);

            // Add listener to update button state
            linkController.addListener(() {
              setDialogState(() {});
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with avatars
                    CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      radius: 30,
                      child: const Icon(
                        Icons.language_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Confluence',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Import Link Website',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Website name input field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter knowledge unit name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: linkController,
                      decoration: InputDecoration(
                        labelText: 'Wiki Page URL',
                        hintText: 'hpps://wiki.example.com/page',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your Confluence username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Link input field
                    TextField(
                      controller: apiTokenController,
                      decoration: InputDecoration(
                        labelText: 'API Token',
                        hintText: 'Enter your Confluence API token',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste),
                          onPressed: () {
                            // Handle paste functionality
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          var response = await _knowledgeService
                              .importConfluenceToKnowledge(
                                id: _knowledgeId!,
                                url: linkController.text,
                                knowledgeName: nameController.text,
                                username: usernameController.text,
                                apiToken: apiTokenController.text,
                              );

                          if (response) {
                            setState(() {
                              // Clear the selected file and source
                              _selectedFile = null;
                              _selectedSource = null;
                            });
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to upload website.'),
                              ),
                            );
                          }
                        },
                        // isValid
                        //     ? () {
                        //       setState(() {
                        //         _selectedSource = 'Confluence';
                        //         _knowledge_unit_name = nameController.text;
                        //         _confluence_username =
                        //             usernameController.text;
                        //         _confluence_api_token =
                        //             apiTokenController.text;
                        //         _selectedWebsiteUrl = linkController.text;
                        //       });
                        //       Navigator.pop(context);
                        //     }
                        //     : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF415DF2),
                          disabledBackgroundColor: Colors.grey[300],
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey[500],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSlackDialog(BuildContext context) {
    final nameController = TextEditingController();
    final apiTokenController = TextEditingController();

    bool isValidUrl(String url) {
      try {
        final uri = Uri.parse(url);
        return uri.hasScheme && uri.host.isNotEmpty;
      } catch (e) {
        return false;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // bool isValid = isValidUrl(linkController.text);

            // // Add listener to update button state
            // linkController.addListener(() {
            //   setDialogState(() {});
            // });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with avatars
                    CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      radius: 30,
                      child: const Icon(
                        Icons.language_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your knowledge unit name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste),
                          onPressed: () {
                            // Handle paste functionality
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: apiTokenController,
                      decoration: InputDecoration(
                        labelText: 'Slack Bot Token',
                        hintText: 'Enter your Slack bot token',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste),
                          onPressed: () {
                            // Handle paste functionality
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          var response = await _knowledgeService
                              .importSlackToKnowledge(
                                id: _knowledgeId!,
                                knowledgeName: nameController.text,
                                apiToken: apiTokenController.text,
                              );

                          if (response) {
                            setState(() {
                              // Clear the selected file and source
                              _selectedFile = null;
                              _selectedSource = null;
                            });
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to upload website.'),
                              ),
                            );
                          }
                        },
                        // isValid
                        //     ? () {
                        //       setState(() {
                        //         _selectedSource = 'Confluence';
                        //         _knowledge_unit_name = nameController.text;
                        //         _confluence_username =
                        //             usernameController.text;
                        //         _confluence_api_token =
                        //             apiTokenController.text;
                        //         _selectedWebsiteUrl = linkController.text;
                        //       });
                        //       Navigator.pop(context);
                        //     }
                        //     : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF415DF2),
                          disabledBackgroundColor: Colors.grey[300],
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey[500],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSourceSelectionDialog(
    BuildContext context,
    List<Map<String, dynamic>> sources,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Center(
                  child: SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Fix potential overflow by limiting the number of avatars
                        for (int i = 0; i < 3 && i < sources.length; i++)
                          Positioned(
                            left: 80 + (i * 20),
                            child: CircleAvatar(
                              backgroundColor: sources[i]['avatarColor'],
                              radius: 20,
                              child: Icon(
                                sources[i]['icon'],
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dialog title
                const Center(
                  child: Text(
                    "Select Knowledge Source",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                // Source options with direct navigation - FIX OVERFLOW
                for (int i = 0; i < sources.length; i++)
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop(); // Close dialog

                      // Update selected source
                      setState(() {
                        _selectedSource = sources[i]['title'];
                      });

                      // Handle navigation based on selection
                      if (i == 0) {
                        // Local files
                        _showFileUploadDialog(context);
                      } else if (i == 1) {
                        // Website
                        _showWebsiteDialog(context);
                      } else if (i == 3) {
                        // Website
                        _showSlackDialog(context);
                      } else if (i == 4) {
                        // Website
                        _showConfluenceDialog(context);
                      } else {
                        // For other options, you could navigate to different screens
                        debugPrint("Selected source: ${sources[i]['title']}");
                        // Navigator.of(context).pushNamed('/next-screen', arguments: sources[i]);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          // Source avatar
                          CircleAvatar(
                            backgroundColor: sources[i]['avatarColor'],
                            radius: 20,
                            child: Icon(
                              sources[i]['icon'],
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Source details with Expanded
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sources[i]['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sources[i]['description'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Arrow indicator - ensure it doesn't cause overflow
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedWebsite() {
    if (_selectedWebsiteUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.language_outlined,
              color: Colors.purple[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedWebsiteUrl!,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedWebsiteUrl = null;
                _selectedSource = null;
              });
            },
            color: Colors.grey[400],
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter prompts based on current filters
    final displayedPrompts = _datasources;
    final sources = [
      {
        'title': 'Local files',
        'description': 'Upload pdf, docx,...',
        'icon': FontAwesomeIcons.folder,
        'avatarColor': Colors.blue[100]!,
      },
      {
        'title': 'Website',
        'description': 'Connect Website to get data',
        'icon': FontAwesomeIcons.globe,
        'avatarColor': Colors.purple[100]!,
      },
      {
        'title': 'Google Drive',
        'description': 'Import Link Drive',
        'icon': FontAwesomeIcons.googleDrive,
        'avatarColor': Colors.orange[100]!,
      },
      {
        'title': 'Slack',
        'description': 'Import Link Slack',
        'icon': FontAwesomeIcons.slack,
        'avatarColor': Colors.green[100]!,
      },
      {
        'title': 'Confluence',
        'description': 'Import Link Confluence',
        'icon': FontAwesomeIcons.atlassian,
        'avatarColor': Colors.yellowAccent[100]!,
      },
    ];

    return Focus(
      focusNode: _screenFocusNode,
      child: BaseScreen(
        title: 'Datasource',
        showBackButton: true,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search Source',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 16),

              // Knowledge Name
              _buildSectionTitle('Add Knowledge'),
              InkWell(
                onTap: () => _showSourceSelectionDialog(context, sources),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.source_outlined,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedSource ?? 'Select Source',
                          style: TextStyle(
                            color:
                                _selectedSource != null
                                    ? Colors.black
                                    : Colors.grey,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),

              // Selected file or website display
              if (_selectedSource == 'Local files')
                _buildSelectedFile()
              else if (_selectedSource == 'Website')
                _buildSelectedWebsite(),

              const SizedBox(height: 16),
              // Filter options

              // Prompt count
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Text(
                      '$_totalDatasources Datasource Available',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Prompt list
              Expanded(
                child:
                    _hasError
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Failed to load prompts',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed:
                                    () => _loadDatasources(refresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : _isLoading && _datasources.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : displayedPrompts.isEmpty
                        ? Center(
                          child: Text(
                            showFavoritesOnly
                                ? 'No favorite prompts yet'
                                : 'No prompts available',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () => _loadDatasources(refresh: true),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  !_isLoading &&
                                  _hasMoreDatasource) {
                                _loadDatasources();
                                return true;
                              }
                              return false;
                            },
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount:
                                  displayedPrompts.length +
                                  (_hasMoreDatasource ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at the bottom when loading more items
                                if (index == displayedPrompts.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final datasource = displayedPrompts[index];
                                final Color avatarColor =
                                    index % 2 == 0
                                        ? Colors.blue
                                        : Colors.purple;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(
                                          13,
                                        ), // 0.05 opacity
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      datasource.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        datasource.metadata.fileId != null
                                            ? datasource.metadata.fileId!
                                            : 'No metadata available',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: avatarColor,
                                      child: Text(
                                        datasource.name.isNotEmpty
                                            ? datasource.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Tooltip(
                                          message:
                                              datasource.status
                                                  ? 'Disable Datasource'
                                                  : 'Enable Datasource',
                                          child: IconButton(
                                            icon: Icon(
                                              datasource.status
                                                  ? Icons.toggle_on
                                                  : Icons.toggle_off,
                                              color:
                                                  datasource.status
                                                      ? Colors.green
                                                      : Colors.grey,
                                            ),
                                            onPressed: () async {
                                              // _handleToggleDatasourceStatus()

                                              var response =
                                                  await _knowledgeService
                                                      .handleDisabledDatasource(
                                                        knowledgeId:
                                                            _knowledgeId!,
                                                        datasourceId:
                                                            datasource.id!,
                                                        datasourceStatus:
                                                            datasource.status,
                                                      );
                                              if (response) {
                                                _loadDatasources(refresh: true);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Datasource status updated',
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Failed to update datasource status',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Delete Datasource',
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                () => {
                                                  _showDeleteConfirmation(
                                                    context,
                                                    datasource.name,
                                                    datasource.id!,
                                                  ),
                                                },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
