import 'package:flutter/material.dart';
import 'package:amd_chat_ai/model/assistant.dart';
import 'package:amd_chat_ai/model/knowledge.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/service/assistant_service.dart';
import 'package:amd_chat_ai/service/knowledge_service.dart';

class UpdateAssistantScreen extends StatefulWidget {
  const UpdateAssistantScreen({super.key});

  @override
  State<UpdateAssistantScreen> createState() => _UpdateAssistantScreenState();
}

class _UpdateAssistantScreenState extends State<UpdateAssistantScreen> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Multi-select knowledge bases
  List<String> _selectedKnowledgeNames = [];
  List<String> _selectedKnowledgeIds = [];

  bool _isLoading = false;
  bool _isLoadingKnowledges = true;
  String? _errorMessage;

  // For API integration
  final AssistantService _assistantService = AssistantService();
  final KnowledgeService _knowledgeService = KnowledgeService();
  Assistant? _assistant;
  String? _assistantId;

  // Knowledge data from API
  List<Knowledge> _knowledgeList = [];
  List<Knowledge> _assistantKnowledges = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get assistant data from route arguments if not already initialized
    if (_assistant == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Assistant) {
        _assistant = args;
        _assistantId = _assistant?.id;
        _initializeFormFields();
        _fetchAssistantKnowledges();
      } else if (args is Map<String, dynamic>) {
        _assistantId = args['id'] as String?;
        _initializeFormFieldsFromMap(args);
        if (_assistantId != null) {
          _fetchAssistantKnowledges();
        }
      }
    }
  }

  Future<void> _fetchAssistantKnowledges() async {
    if (_assistantId == null) return;

    setState(() {
      _isLoadingKnowledges = true;
    });

    try {
      // Fetch all available knowledge bases
      final knowledgeResponse = await _knowledgeService.getKnowledges(
        limit: 50, // Get a reasonable number of knowledge bases
      );

      // Fetch knowledge bases associated with this assistant
      final assistantKnowledgesResponse = await _assistantService
          .getAssistantKnowledges(assistantId: _assistantId!, limit: 50);

      setState(() {
        _isLoadingKnowledges = false;

        // Set available knowledge bases
        if (knowledgeResponse != null) {
          _knowledgeList = knowledgeResponse.data;
        }

        // Set knowledge bases associated with this assistant
        if (assistantKnowledgesResponse != null) {
          _assistantKnowledges = assistantKnowledgesResponse.data;

          // Pre-select the assistant's knowledge bases
          _selectedKnowledgeIds =
              _assistantKnowledges.map((knowledge) => knowledge.id!).toList();

          _selectedKnowledgeNames =
              _assistantKnowledges
                  .map((knowledge) => knowledge.knowledgeName)
                  .toList();
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingKnowledges = false;
        _errorMessage = 'Failed to load knowledge bases: $e';
      });
    }
  }

  void _initializeFormFields() {
    if (_assistant != null) {
      _nameController.text = _assistant!.assistantName;
      _instructionsController.text = _assistant!.instructions;
      _descriptionController.text = _assistant!.description;
    }
  }

  void _initializeFormFieldsFromMap(Map<String, dynamic> data) {
    _nameController.text = data['assistantName'] as String? ?? '';
    _instructionsController.text = data['instructions'] as String? ?? '';
    _descriptionController.text = data['description'] as String? ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateAssistant() async {
    if (_assistantId == null) {
      setState(() {
        _errorMessage = 'Cannot update assistant: missing ID';
      });
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _instructionsController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please complete all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Update only the assistant's basic information
      final updatedAssistant = await _assistantService.updateAssistant(
        assistantId: _assistantId!,
        assistantName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        instructions: _instructionsController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (updatedAssistant != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assistant updated successfully')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Assistant update failed
        setState(() {
          _errorMessage = 'Failed to update assistant. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Update Assistant',
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(
                        255,
                        0,
                        0,
                        0.1,
                      ), // 0.1 opacity
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Assistant Name
              _buildSectionTitle('Assistant Name'),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter assistant name',
                prefixIcon: Icons.smart_toy_outlined,
                maxLines: 1,
              ),

              const SizedBox(height: 24),

              // Instructions
              _buildSectionTitle('Instructions'),
              _buildTextField(
                controller: _instructionsController,
                hintText: 'What should your AI assistant do?',
                prefixIcon: Icons.lightbulb_outline,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Description
              _buildSectionTitle('Description'),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Describe your AI assistant...',
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Knowledge Selection with Searchable Dropdown
              _buildSectionTitle('Knowledge Base (Multi-Select)'),
              _isLoadingKnowledges
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withAlpha(51),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            _showMultiSelectDialog(context);
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.library_books_outlined,
                                color: Color(0xFF3B5998),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedKnowledgeNames.isEmpty
                                      ? 'Select Knowledge Bases'
                                      : '${_selectedKnowledgeNames.length} Knowledge Base(s) Selected',
                                  style: TextStyle(
                                    color:
                                        _selectedKnowledgeNames.isEmpty
                                            ? Colors.black54
                                            : Colors.black87,
                                    fontSize: 16,
                                    fontWeight:
                                        _selectedKnowledgeNames.isEmpty
                                            ? FontWeight.w400
                                            : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF3B5998).withAlpha(77),
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedKnowledgeNames.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              _selectedKnowledgeNames.length,
                              (index) => Chip(
                                label: Text(
                                  _selectedKnowledgeNames[index],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF3B5998),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onDeleted: () {
                                  // Show confirmation dialog before removing the knowledge base
                                  _showDeleteConfirmationDialog(
                                    context,
                                    _selectedKnowledgeIds[index],
                                    _selectedKnowledgeNames[index],
                                    index,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
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
                      color: const Color.fromRGBO(65, 93, 242, 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color.fromRGBO(65, 93, 242, 1.0),
                            ),
                          ),
                        )
                        : ElevatedButton(
                          onPressed: _updateAssistant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              65,
                              93,
                              242,
                              1.0,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Update Assistant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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

  // Add multi-select dialog method
  Future<void> _showMultiSelectDialog(BuildContext context) async {
    final List<String> tempSelectedIds = List.from(_selectedKnowledgeIds);
    // Keep track of initial selection to check what was removed later
    final Set<String> initialSelectedIds = Set.from(_selectedKnowledgeIds);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Text(
                      'Select Knowledge Bases',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B5998),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search Knowledge Bases',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF3B5998),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          // Filter functionality could be added here
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List of Knowledge Bases with checkboxes
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _knowledgeList.length,
                        itemBuilder: (context, index) {
                          final knowledge = _knowledgeList[index];
                          final isSelected = tempSelectedIds.contains(
                            knowledge.id,
                          );
                          // Check if this is a pre-selected knowledge from assistant
                          final isPreviouslySelected = initialSelectedIds
                              .contains(knowledge.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  if (!tempSelectedIds.contains(knowledge.id)) {
                                    tempSelectedIds.add(knowledge.id!);
                                  }
                                } else {
                                  tempSelectedIds.remove(knowledge.id);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    knowledge.knowledgeName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isPreviouslySelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        59,
                                        89,
                                        152,
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF3B5998),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              knowledge.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            activeColor: const Color(0xFF3B5998),
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Find knowledge bases that were unchecked (removed)
                            final Set<String> uncheckedIds = initialSelectedIds
                                .difference(Set.from(tempSelectedIds));

                            // Find knowledge bases that were newly selected (added)
                            final Set<String> newlyAddedIds = Set<String>.from(
                              tempSelectedIds,
                            ).difference(initialSelectedIds);

                            if (uncheckedIds.isNotEmpty) {
                              // Get names of unchecked knowledge bases
                              final List<String> uncheckedNames =
                                  uncheckedIds.map((id) {
                                    final knowledge = _assistantKnowledges
                                        .firstWhere(
                                          (k) => k.id == id,
                                          orElse:
                                              () => Knowledge(
                                                knowledgeName: 'Unknown',
                                                description: '',
                                              ),
                                        );
                                    return knowledge.knowledgeName;
                                  }).toList();

                              // Close the multi-select dialog first
                              Navigator.of(context).pop();

                              // Show confirmation dialog for deleting unchecked knowledge bases
                              _showBulkDeleteConfirmationDialog(
                                context,
                                uncheckedIds.toList(),
                                uncheckedNames,
                                tempSelectedIds,
                                newlyAddedIds.toList(),
                              );
                            } else if (newlyAddedIds.isNotEmpty) {
                              // Close dialog first
                              Navigator.of(context).pop();

                              // Immediately import new knowledge bases
                              _importNewKnowledgeBases(
                                newlyAddedIds.toList(),
                                tempSelectedIds,
                              );
                            } else {
                              // No changes, just update the UI
                              this.setState(() {
                                _selectedKnowledgeIds = List.from(
                                  tempSelectedIds,
                                );
                                _selectedKnowledgeNames =
                                    _selectedKnowledgeIds.map((id) {
                                      final knowledge = _knowledgeList
                                          .firstWhere(
                                            (k) => k.id == id,
                                            orElse:
                                                () => Knowledge(
                                                  knowledgeName: 'Unknown',
                                                  description: '',
                                                ),
                                          );
                                      return knowledge.knowledgeName;
                                    }).toList();
                              });
                              Navigator.of(context).pop();
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B5998),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
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

  // Add method to confirm deletion of multiple knowledge bases
  Future<void> _showBulkDeleteConfirmationDialog(
    BuildContext context,
    List<String> knowledgeIdsToDelete,
    List<String> knowledgeNamesToDelete,
    List<String> newSelectionIds,
    List<String> newlyAddedIds,
  ) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (BuildContext dialogContext, _, __) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5A5F), Color(0xFFFF414D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Warning Icon with glowing effect
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(26),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_sweep_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'Confirm Bulk Removal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description Text
                      const Text(
                        'You have unchecked the following knowledge bases:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Knowledge List Box
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade50,
                                Colors.grey.shade100.withAlpha(128),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.withAlpha(26),
                              width: 1,
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  knowledgeNamesToDelete.map((name) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withAlpha(51),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF444444),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirmation Question
                      const Text(
                        'Do you want to remove these knowledge bases from this assistant?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Warning box with enhanced styling
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade50,
                              Colors.red.shade100.withAlpha(128),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.red.withAlpha(64),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withAlpha(51),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'This action cannot be undone. All associated data will be permanently removed.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons with enhanced styling
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Cancel button
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                // Reopen the multi-select dialog to let the user continue selection
                                _showMultiSelectDialog(context);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF666666),
                                backgroundColor: Colors.grey.withAlpha(26),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Remove button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(
                                      255,
                                      65,
                                      77,
                                      0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5A5F),
                                    Color(0xFFFF414D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(dialogContext).pop();

                                  setState(() {
                                    _isLoading = true;
                                  });

                                  // Track deletions
                                  final List<String> successfullyDeleted = [];
                                  final List<String> failedToDelete = [];

                                  // Process each knowledge base to delete
                                  for (
                                    int i = 0;
                                    i < knowledgeIdsToDelete.length;
                                    i++
                                  ) {
                                    final knowledgeId = knowledgeIdsToDelete[i];
                                    final knowledgeName =
                                        knowledgeNamesToDelete[i];

                                    if (_assistantId != null) {
                                      final success = await _assistantService
                                          .deleteKnowledgeFromAssistant(
                                            _assistantId!,
                                            knowledgeId,
                                          );

                                      if (success) {
                                        successfullyDeleted.add(knowledgeName);
                                        // Remove from assistant knowledge list
                                        _assistantKnowledges.removeWhere(
                                          (knowledge) =>
                                              knowledge.id == knowledgeId,
                                        );
                                      } else {
                                        failedToDelete.add(knowledgeName);
                                      }
                                    }
                                  }

                                  // Update the main state with the new selection
                                  setState(() {
                                    _isLoading = false;

                                    // Update selected knowledge IDs and names based on deletion results
                                    _selectedKnowledgeIds = newSelectionIds;
                                    _selectedKnowledgeNames =
                                        _selectedKnowledgeIds.map((id) {
                                          final knowledge = _knowledgeList
                                              .firstWhere(
                                                (k) => k.id == id,
                                                orElse:
                                                    () => Knowledge(
                                                      knowledgeName: 'Unknown',
                                                      description: '',
                                                    ),
                                              );
                                          return knowledge.knowledgeName;
                                        }).toList();

                                    // Show appropriate messages
                                    if (failedToDelete.isNotEmpty) {
                                      if (successfullyDeleted.isEmpty) {
                                        _errorMessage =
                                            'Failed to remove any knowledge bases from this assistant.';
                                      } else {
                                        _errorMessage =
                                            'Failed to remove some knowledge bases: ${failedToDelete.join(", ")}';
                                      }

                                      // Store context reference for later use
                                      final currentContext = context;

                                      // Scroll to top to show error message
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        () {
                                          if (mounted) {
                                            Scrollable.ensureVisible(
                                              currentContext,
                                              alignment: 0.0,
                                              duration: const Duration(
                                                milliseconds: 600,
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    }
                                  });

                                  // Store context before async operation
                                  final currentContext = context;

                                  // Show success message outside of setState
                                  if (successfullyDeleted.isNotEmpty &&
                                      mounted) {
                                    ScaffoldMessenger.of(
                                      currentContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          successfullyDeleted.length == 1
                                              ? 'Successfully removed "${successfullyDeleted.first}" from this assistant'
                                              : 'Successfully removed ${successfullyDeleted.length} knowledge bases from this assistant',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }

                                  // If there are newly added knowledge bases, import them now
                                  if (newlyAddedIds.isNotEmpty) {
                                    _importNewKnowledgeBases(
                                      newlyAddedIds,
                                      newSelectionIds,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Remove All',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
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

  // Add method to import new knowledge bases
  Future<void> _importNewKnowledgeBases(
    List<String> knowledgeIdsToImport,
    List<String> allSelectedIds,
  ) async {
    if (_assistantId == null || knowledgeIdsToImport.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Track imports
    final List<String> successfullyImported = [];
    final List<String> failedToImport = [];

    // Process each knowledge base to import
    for (final knowledgeId in knowledgeIdsToImport) {
      final knowledge = _knowledgeList.firstWhere(
        (k) => k.id == knowledgeId,
        orElse: () => Knowledge(knowledgeName: 'Unknown', description: ''),
      );

      final knowledgeName = knowledge.knowledgeName;

      debugPrint('Importing knowledge: $knowledgeName (ID: $knowledgeId)');

      final success = await _assistantService.importKnowledgeToAssistant(
        _assistantId!,
        knowledgeId,
      );

      if (success) {
        successfullyImported.add(knowledgeName);
        // Add to assistant knowledge list
        if (!_assistantKnowledges.any((k) => k.id == knowledgeId)) {
          _assistantKnowledges.add(knowledge);
        }
      } else {
        failedToImport.add(knowledgeName);
      }
    }

    // Update the main state with the new selection
    setState(() {
      _isLoading = false;

      // Update selected knowledge IDs and names
      _selectedKnowledgeIds = allSelectedIds;
      _selectedKnowledgeNames =
          _selectedKnowledgeIds.map((id) {
            final knowledge = _knowledgeList.firstWhere(
              (k) => k.id == id,
              orElse:
                  () => Knowledge(knowledgeName: 'Unknown', description: ''),
            );
            return knowledge.knowledgeName;
          }).toList();

      // Show appropriate messages
      if (failedToImport.isNotEmpty) {
        if (successfullyImported.isEmpty) {
          _errorMessage =
              'Failed to import any knowledge bases to this assistant.';
        } else {
          _errorMessage =
              'Failed to import some knowledge bases: ${failedToImport.join(", ")}';
        }

        // Store context reference for later use
        final currentContext = context;

        // Scroll to top to show error message
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Scrollable.ensureVisible(
              currentContext,
              alignment: 0.0,
              duration: const Duration(milliseconds: 600),
            );
          }
        });
      }
    });
  }

  // Add delete confirmation dialog method
  Future<void> _showDeleteConfirmationDialog(
    BuildContext parentContext,
    String knowledgeId,
    String knowledgeName,
    int index,
  ) async {
    await showGeneralDialog(
      context: parentContext,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (BuildContext dialogContext, _, __) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5A5F), Color(0xFFFF414D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Warning Icon with glowing effect
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(26),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'Confirm Removal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Knowledge name with highlight
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 17,
                            color: Color(0xFF555555),
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Are you sure you want to remove ',
                            ),
                            TextSpan(
                              text: '"$knowledgeName"',
                              style: const TextStyle(
                                color: Color(0xFF3B5998),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' from this assistant?'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Warning box with enhanced styling
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade50,
                              Colors.red.shade100.withAlpha(128),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.red.withAlpha(64),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withAlpha(51),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'This action cannot be undone. All associated data will be permanently removed.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons with enhanced styling
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Cancel button
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF666666),
                                backgroundColor: Colors.grey.withAlpha(26),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Remove button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(
                                      255,
                                      65,
                                      77,
                                      0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5A5F),
                                    Color(0xFFFF414D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Store the context before the async operation
                                  final outerContext = parentContext;
                                  Navigator.of(dialogContext).pop();

                                  // Show loading indicator
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  // Delete the knowledge base from the assistant
                                  if (_assistantId != null) {
                                    final success = await _assistantService
                                        .deleteKnowledgeFromAssistant(
                                          _assistantId!,
                                          knowledgeId,
                                        );

                                    // Handle the result
                                    setState(() {
                                      _isLoading = false;

                                      if (success) {
                                        // Remove from the selected lists
                                        _selectedKnowledgeIds.removeAt(index);
                                        _selectedKnowledgeNames.removeAt(index);

                                        // Also remove from the assistant knowledge list if present
                                        _assistantKnowledges.removeWhere(
                                          (knowledge) =>
                                              knowledge.id == knowledgeId,
                                        );

                                        // Show success message
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            outerContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Successfully removed "$knowledgeName" from this assistant',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } else {
                                        // Show error message
                                        _errorMessage =
                                            'Failed to remove "$knowledgeName" from this assistant. Please try again.';

                                        // Store context reference from outer scope
                                        final currentContext = outerContext;

                                        // Scroll to top to show error message
                                        Future.delayed(
                                          const Duration(milliseconds: 100),
                                          () {
                                            if (mounted) {
                                              Scrollable.ensureVisible(
                                                currentContext,
                                                alignment: 0.0,
                                                duration: const Duration(
                                                  milliseconds: 600,
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      }
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
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
