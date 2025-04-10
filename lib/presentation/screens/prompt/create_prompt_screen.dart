import 'package:flutter/material.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/primary_button.dart';
import 'package:amd_chat_ai/service/prompt_service.dart';

class CreatePromptScreen extends StatefulWidget {
  const CreatePromptScreen({super.key});

  @override
  State<CreatePromptScreen> createState() => _CreatePromptScreenState();
}

class _CreatePromptScreenState extends State<CreatePromptScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedLanguage;
  bool _isPublic = false;
  bool _isLoading = false;

  final PromptService _promptService = PromptService();

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
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Method to create a new prompt
  Future<void> _createPrompt() async {
    // Validate inputs
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _promptService.createPrompt(
        title: _titleController.text,
        content: _contentController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        language: _selectedLanguage!,
        isPublic: _isPublic,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt created successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create prompt')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating prompt: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Create Prompt',
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                hintText: 'Write your prompt content here...',
                prefixIcon: Icons.edit_note,
                maxLines: 8,
              ),

              const SizedBox(height: 24),

              // Description
              _buildSectionTitle('Description'),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Describe what this prompt does',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Category
              _buildSectionTitle('Category'),
              Container(
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: const Text('Select a category'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items:
                        _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Language Dropdown
              _buildSectionTitle('Language'),
              Container(
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    hint: const Text('Select a language'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items:
                        _languages.map((String language) {
                          return DropdownMenuItem<String>(
                            value: language,
                            child: Text(language),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Public/Private Toggle
              _buildSectionTitle('Visibility'),
              Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Make this prompt public',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                      activeColor: const Color(0xFF415DF2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Create Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                    label: 'Create Prompt',
                    onPressed: _createPrompt,
                  ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
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
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
