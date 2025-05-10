import 'package:amd_chat_ai/model/datasource.dart';
import 'package:amd_chat_ai/service/knowledge_service.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/primary_button.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/file_picker_widget.dart';

class UpdateKnowledgeScreen extends StatefulWidget {
  const UpdateKnowledgeScreen({super.key});

  @override
  State<UpdateKnowledgeScreen> createState() => _UpdateKnowledgeScreenState();
}

class _UpdateKnowledgeScreenState extends State<UpdateKnowledgeScreen>
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

  List<Datasource> _datasourceItems = [];
  bool _isFetching = false;
  int _offset = 0;
  final int _limit = 10;
  bool _hasNext = true;

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
      final Map<String, dynamic>? knowledgeData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (knowledgeData != null) {
        setState(() {
          _knowledgeId = knowledgeData['id'];
          _nameController.text = knowledgeData['knowledgeName'];
          _descriptionController.text = knowledgeData['description'];
        });
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

  Future<void> _handleUpdateKnowledge() async {
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
      // Call the updateKnowledge function
      final knowledge = await _knowledgeService.updateKnowledge(
        id: _knowledgeId!,
        knowledgeName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (knowledge != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Knowledge "${knowledge}" updated successfully!'),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update knowledge. Please try again.'),
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
    ];

    return BaseScreen(
      title: 'Update Knowledge',
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Knowledge Name
              _buildSectionTitle('Name'),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter name',
                prefixIcon: Icons.bookmark_border_rounded,
                maxLines: 1,
              ),

              const SizedBox(height: 24),

              // Description
              _buildSectionTitle('Description'),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Describe knowledge ...',
                prefixIcon: Icons.description_outlined,
                maxLines: 5,
              ),

              const SizedBox(height: 24),

              // _buildSectionTitle('Data Source'),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/datasource',
                    arguments: {'knowledgeId': _knowledgeId},
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View Data Sources',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Update Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                    label: 'Update Knowledge',
                    onPressed: _handleUpdateKnowledge,
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

  // Also update the source selection dialog to fix potential overflow
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

  // Also update the website dialog to fix potential overflow
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
