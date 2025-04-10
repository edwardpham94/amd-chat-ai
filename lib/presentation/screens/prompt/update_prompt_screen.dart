import 'package:flutter/material.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/service/prompt_service.dart';

class UpdatePromptScreen extends StatefulWidget {
  const UpdatePromptScreen({super.key});

  @override
  State<UpdatePromptScreen> createState() => _UpdatePromptScreenState();
}

class _UpdatePromptScreenState extends State<UpdatePromptScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedLanguage;
  bool _isPublic = false;
  String? _promptId;
  String? _promptUserId;
  bool _isLoading = false;
  bool _canEdit = false;

  final PromptService _promptService = PromptService();

  // Method to check if current user is the owner of the prompt
  Future<void> _checkUserPermission() async {
    final currentUserId = await UserStorage.getUserId();
    setState(() {
      _canEdit = currentUserId == _promptUserId;
    });
    debugPrint(
      'Current user: $currentUserId, Prompt user: $_promptUserId, Can edit: $_canEdit',
    );
  }

  final List<String> _categories = [
    'business',
    'career',
    'chatbot',
    'coding',
    'education',
    'fun',
    'marketing',
    'productivity',
    'seo',
    'writing',
    'other',
  ];

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Korean',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Get the arguments passed from the previous screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? promptData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (promptData != null) {
        // Get category and ensure it's in the list
        String category = promptData['category'] ?? 'other';
        if (!_categories.contains(category)) {
          category = 'other';
        }

        // Get language and ensure it's in the list
        String language = promptData['language'] ?? 'English';
        if (!_languages.contains(language)) {
          language = 'English';
        }

        setState(() {
          _promptId = promptData['id'];
          _promptUserId = promptData['userId'];
          _titleController.text = promptData['title'] ?? '';
          _contentController.text = promptData['content'] ?? '';
          _descriptionController.text = promptData['description'] ?? '';
          _selectedCategory = category;
          _selectedLanguage = language;
          _isPublic = promptData['isPublic'] ?? false;
        });

        debugPrint('Loaded prompt data: $promptData');
        debugPrint(
          'Selected category: $_selectedCategory, Selected language: $_selectedLanguage',
        );

        // Check if current user is the owner of the prompt
        _checkUserPermission();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updatePrompt() async {
    // Validate required fields according to API requirements
    if (_descriptionController.text.isEmpty || _promptId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Description is required')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure category and language are valid
      String category = _selectedCategory ?? 'other';
      if (!_categories.contains(category)) {
        category = 'other';
      }

      String language = _selectedLanguage ?? 'English';
      if (!_languages.contains(language)) {
        language = 'English';
      }

      // Description validation already done at the beginning of the method

      final success = await _promptService.updatePrompt(
        promptId: _promptId!,
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        content:
            _contentController.text.isNotEmpty ? _contentController.text : null,
        description: _descriptionController.text,
        category: category,
        language: language,
        isPublic: _isPublic,
      );

      debugPrint('Update prompt with category: $category, language: $language');

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt updated successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update prompt')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating prompt: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Update Prompt',
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show a message if the user can't edit the prompt
              if (!_canEdit)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You cannot edit this prompt because you are not the owner.',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              // Title
              _buildSectionTitle('Title'),
              _buildTextField(
                controller: _titleController,
                hintText: 'Enter prompt title',
                prefixIcon: Icons.title,
                maxLines: 1,
              ),

              const SizedBox(height: 24),

              // Content
              _buildSectionTitle('Content'),
              _buildTextField(
                controller: _contentController,
                hintText: 'Write your prompt content...',
                prefixIcon: Icons.edit_note_rounded,
                maxLines: 5,
              ),

              const SizedBox(height: 24),

              // Description
              _buildSectionTitle('Description'),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Describe your prompt...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Category Dropdown
              _buildSectionTitle('Category'),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value:
                      _selectedCategory != null &&
                              _categories.contains(_selectedCategory)
                          ? _selectedCategory
                          : 'other',
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                      color: Color(0xFF3B5998),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  hint: const Text('Select category'),
                  items:
                      _categories.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged:
                      _canEdit
                          ? (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                          : null,
                ),
              ),

              const SizedBox(height: 24),

              // Language Dropdown
              _buildSectionTitle('Language'),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value:
                      _selectedLanguage != null &&
                              _languages.contains(_selectedLanguage)
                          ? _selectedLanguage
                          : 'English',
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.language,
                      color: Color(0xFF3B5998),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  hint: const Text('Select language'),
                  items:
                      _languages.map((String language) {
                        return DropdownMenuItem(
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                  onChanged:
                      _canEdit
                          ? (String? newValue) {
                            setState(() {
                              _selectedLanguage = newValue;
                            });
                          }
                          : null,
                ),
              ),

              const SizedBox(height: 24),

              // Public/Private Toggle
              _buildSectionTitle('Visibility'),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(
                    _isPublic ? Icons.public : Icons.lock_outline,
                    color: const Color(0xFF3B5998),
                  ),
                  title: Text(_isPublic ? 'Public' : 'Private'),
                  trailing: Switch(
                    value: _isPublic,
                    onChanged:
                        _canEdit
                            ? (bool value) {
                              setState(() {
                                _isPublic = value;
                              });
                            }
                            : null,
                    activeColor: const Color(0xFF415DF2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Update Button
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
                  onPressed: (_isLoading || !_canEdit) ? null : _updatePrompt,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF415DF2),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : !_canEdit
                          ? const Text(
                            'Cannot edit - Not your prompt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          )
                          : const Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
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
        enabled: _canEdit,
        style: TextStyle(
          fontSize: 16,
          color: _canEdit ? Colors.black : Colors.grey,
        ),
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
