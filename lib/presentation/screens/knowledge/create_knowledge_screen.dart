import 'package:amd_chat_ai/service/knowledge_service.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/primary_button.dart';

class CreateKnowledgeScreen extends StatefulWidget {
  const CreateKnowledgeScreen({super.key});

  @override
  State<CreateKnowledgeScreen> createState() => _CreateKnowledgeScreenState();
}

class _CreateKnowledgeScreenState extends State<CreateKnowledgeScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSource;
  late AnimationController _animationController;
  final KnowledgeService _knowledgeService = KnowledgeService();
  bool _isLoading = false;

  Map<String, dynamic>? _selectedFile;
  String? _selectedWebsiteUrl;
  String? _selectedWebsiteName;
  String? _knowledgeId;

  String? _knowledge_unit_name;
  String? _confluence_username;
  String? _confluence_api_token;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();

    // Retrieve the ID from the arguments and fetch knowledge details if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) {
        _knowledgeId = args;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateKnowledge() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a knowledge name')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the createKnowledge function
      final knowledge = await _knowledgeService.createKnowledge(
        knowledgeName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (knowledge != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Knowledge "${knowledge.knowledgeName}" created successfully!',
            ),
          ),
        );

        // Get the ID of the created knowledge
        final String knowledgeId = knowledge.id ?? '';

        if (_selectedFile != null && _selectedFile!['path'] != null) {
          // Upload the local file
          final String filePath = _selectedFile!['path'];
          final responseId = await _knowledgeService.uploadLocalFile(
            filePath: filePath,
          );

          if (responseId != null) {
            // Import the file to the knowledge
            final success = await _knowledgeService.importDataSourceToKnowledge(
              id: knowledgeId,
              fileName: _selectedFile!['name'],
              fileId: responseId,
              type: 'file',
            );

            if (success) {
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

        if (_selectedSource == 'Website') {
          print(
            'Selected website URL: $_selectedWebsiteName $_selectedWebsiteUrl ',
          );
          final success = await _knowledgeService.uploadFromWebsite(
            id: knowledgeId,
            webUrl: _selectedWebsiteUrl!,
            unitName: _selectedWebsiteName!,
          );

          if (success) {
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

        if (_selectedSource == 'Slack') {
          print(
            'Selected Slack URL: $_selectedWebsiteName $_selectedWebsiteUrl ',
          );
          final success = await _knowledgeService.importSlackToKnowledge(
            id: knowledgeId,
            apiToken: _confluence_api_token!,
            knowledgeName: _knowledge_unit_name!,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attached Slack successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload Slack. Please try again.'),
              ),
            );
          }
        }

        if (_selectedSource == 'Confluence') {
          print(
            'Selected Confluence URL: $_selectedWebsiteName $_selectedWebsiteUrl ',
          );
          final success = await _knowledgeService.importConfluenceToKnowledge(
            id: knowledgeId,
            username: _confluence_username!,
            apiToken: _confluence_api_token!,
            url: _selectedWebsiteUrl!,
            knowledgeName: _knowledge_unit_name!,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attached Confluence successfully!'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload Confluence. Please try again.'),
              ),
            );
          }
        }

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create knowledge. Please try again.'),
          ),
        );
      }
    } on DioException catch (e) {
      debugPrint('Error creating knowledge: ${e.response?.data ?? e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.response?.data['message'] ?? 'An unexpected error occurred.'}',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sources data with more details
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

    return BaseScreen(
      title: _knowledgeId == null ? 'Create Knowledge' : 'Edit Knowledge',
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Knowledge Name
              _buildSectionTitle('Knowledge Name'),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter knowledge name',
                prefixIcon: Icons.bookmark_border_rounded,
                maxLines: 1,
              ),

              const SizedBox(height: 24),

              // Description
              _buildSectionTitle('Description'),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Describe your knowledge resource...',
                prefixIcon: Icons.description_outlined,
                maxLines: 5,
              ),

              const SizedBox(height: 24),

              // Import Knowledge - Replace the dropdown with a button
              _buildSectionTitle('Import Knowledge'),
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

              const SizedBox(height: 48),

              // Create Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                    label:
                        _knowledgeId == null
                            ? 'Create Knowledge'
                            : 'Update Knowledge',
                    onPressed: _handleCreateKnowledge,
                  ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Update the file upload dialog
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

  // Add this widget to display selected file
  Widget _buildSelectedFile() {
    if (_selectedFile == null) return const SizedBox.shrink();

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
                        onPressed: () {
                          setState(() {
                            _selectedSource = 'Slack';
                            _knowledge_unit_name = nameController.text;
                            _confluence_api_token = apiTokenController.text;
                          });
                          Navigator.pop(context);
                        },
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


  // Add this widget to display selected website
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
                      }
                      // _showConfluenceDialog
                      else {
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

  // Also update the website dialog to fix potential overflow
  void _showWebsiteDialog(BuildContext context) {
    final linkController = TextEditingController();
    final nameController =
        TextEditingController();

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
                        onPressed:
                            isValid
                                ? () {
                                  setState(() {
                                    _selectedSource = 'Confluence';
                                    _knowledge_unit_name = nameController.text;
                                    _confluence_username =
                                        usernameController.text;
                                    _confluence_api_token =
                                        apiTokenController.text;
                                    _selectedWebsiteUrl = linkController.text;
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(prefixIcon, color: const Color(0xFF3B5998), size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3B5998), width: 1.5),
          ),
        ),
      ),
    );
  }
}
