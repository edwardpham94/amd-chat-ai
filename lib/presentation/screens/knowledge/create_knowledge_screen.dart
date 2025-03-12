import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  Map<String, dynamic>? _selectedFile;
  String? _selectedWebsiteUrl;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
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
        r'icon': FontAwesomeIcons.slack,
        'avatarColor': Colors.green[100]!,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: const Text(
          'Create Knowledge',
          style: TextStyle(
            color: Color(0xFF3B5998),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF415DF2).withAlpha(77),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Handle create knowledge logic
                    final knowledge = {
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                      'source': _selectedSource,
                    };

                    debugPrint('Created knowledge: $knowledge');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF415DF2),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Update the file upload dialog
  void _showFileUploadDialog(BuildContext context) {
    Map<String, dynamic>? tempSelectedFile;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header - FIX OVERFLOW HERE
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload and attach files',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload and attach files to this project.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Upload area
                    GestureDetector(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
                              type: FileType.custom,
                              allowMultiple: false,
                              allowedExtensions: [
                                'pdf',
                                'doc',
                                'docx',
                                'txt',
                                'zip',
                                'jpg',
                                'png',
                                'jpeg',
                                'gif',
                                'bmp',
                                'tiff',
                                'ico',
                              ],
                            );

                        if (result != null) {
                          final file = result.files.first;
                          setDialogState(() {
                            tempSelectedFile = {
                              'name': file.name,
                              'size': '${(file.size / 1024).round()} KB',
                              'progress': 100,
                              'icon': _getFileIcon(file.extension ?? ''),
                            };
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 32,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click to upload and attach files',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF, DOC, DOCX, TXT, ZIP',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Show selected file
                    if (tempSelectedFile != null)
                      Container(
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
                                tempSelectedFile!['icon'],
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
                                    tempSelectedFile!['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Color(0xFF333333),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tempSelectedFile!['size'],
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
                                setDialogState(() {
                                  tempSelectedFile = null;
                                });
                              },
                              color: Colors.grey[400],
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            tempSelectedFile == null
                                ? null
                                : () {
                                  setState(() {
                                    _selectedFile = tempSelectedFile;
                                    _selectedSource = 'Local files';
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

  // Helper method to get appropriate icon based on file extension
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
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
