import 'package:flutter/material.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/primary_button.dart';
import 'package:amd_chat_ai/service/assistant_service.dart';
import 'package:amd_chat_ai/service/knowledge_service.dart';
import 'package:amd_chat_ai/model/knowledge.dart';

class CreateAssistantScreen extends StatefulWidget {
  const CreateAssistantScreen({super.key});

  @override
  State<CreateAssistantScreen> createState() => _CreateAssistantScreenState();
}

class _CreateAssistantScreenState extends State<CreateAssistantScreen> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedKnowledgeNames = [];
  List<String> _selectedKnowledgeIds = [];
  bool _isLoading = false;
  bool _isLoadingKnowledges = true;
  String? _errorMessage;

  final AssistantService _assistantService = AssistantService();
  final KnowledgeService _knowledgeService = KnowledgeService();

  // Knowledge data from API
  List<Knowledge> _knowledgeList = [];

  @override
  void initState() {
    super.initState();
    _fetchKnowledges();
  }

  Future<void> _fetchKnowledges() async {
    setState(() {
      _isLoadingKnowledges = true;
    });

    try {
      final knowledgeResponse = await _knowledgeService.getKnowledges(
        limit: 50, // Get a reasonable number of knowledge bases
      );

      setState(() {
        _isLoadingKnowledges = false;
        if (knowledgeResponse != null) {
          _knowledgeList = knowledgeResponse.data;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingKnowledges = false;
        _errorMessage = 'Failed to load knowledge bases: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createAssistant() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First, create the assistant
      final assistant = await _assistantService.createAssistant(
        assistantName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        instructions: _instructionsController.text.trim(),
      );

      if (assistant != null) {
        // If assistant creation was successful
        debugPrint('Created Assistant with ID: ${assistant.id}');

        // Import each selected knowledge base to the assistant
        if (_selectedKnowledgeIds.isNotEmpty) {
          debugPrint(
            'Importing ${_selectedKnowledgeIds.length} knowledge bases to assistant',
          );

          final List<String> failedImports = [];

          // Process each knowledge ID
          for (int i = 0; i < _selectedKnowledgeIds.length; i++) {
            final knowledgeId = _selectedKnowledgeIds[i];
            final knowledgeName = _selectedKnowledgeNames[i];

            debugPrint(
              'Importing knowledge: $knowledgeName (ID: $knowledgeId)',
            );

            final success = await _assistantService.importKnowledgeToAssistant(
              assistant.id,
              knowledgeId,
            );

            if (!success) {
              failedImports.add(knowledgeName);
              debugPrint('Failed to import knowledge: $knowledgeName');
            }
          }

          // Check if any imports failed
          if (failedImports.isNotEmpty) {
            setState(() {
              _isLoading = false;
              if (failedImports.length == _selectedKnowledgeIds.length) {
                // All imports failed
                _errorMessage =
                    'Assistant created but failed to import any knowledge bases.';
              } else {
                // Some imports failed
                _errorMessage =
                    'Assistant created but failed to import the following knowledge bases: ${failedImports.join(', ')}';
              }
            });
          } else {
            // All imports succeeded
            setState(() {
              _isLoading = false;
            });

            if (mounted) {
              debugPrint(
                'Created Assistant: ${_nameController.text} with ${_selectedKnowledgeIds.length} knowledge bases',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Assistant created successfully with all knowledge bases',
                  ),
                ),
              );
              Navigator.of(
                context,
              ).pop(true); // Return true to indicate success
            }
          }
        } else {
          // No knowledge bases to import
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            debugPrint(
              'Created Assistant: ${_nameController.text} with no knowledge bases',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Assistant created successfully')),
            );
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        }
      } else {
        // Assistant creation failed
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to create assistant. Please try again.';
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
      title: 'Create Assistant',
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
                      color: const Color.fromARGB(26, 255, 0, 0), // 0.1 opacity
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
                                  setState(() {
                                    final idToRemove =
                                        _selectedKnowledgeIds[index];
                                    _selectedKnowledgeIds.removeAt(index);
                                    _selectedKnowledgeNames.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

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
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF415DF2),
                            ),
                          ),
                        )
                        : PrimaryButton(
                          label: 'Create Assistant',
                          onPressed: _createAssistant,
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

  Future<void> _showMultiSelectDialog(BuildContext context) async {
    final List<String> tempSelectedIds = List.from(_selectedKnowledgeIds);

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
                            title: Text(
                              knowledge.knowledgeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
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
                            // Update the main state with selections
                            this.setState(() {
                              _selectedKnowledgeIds = List.from(
                                tempSelectedIds,
                              );
                              _selectedKnowledgeNames =
                                  _selectedKnowledgeIds.map((id) {
                                    final knowledge = _knowledgeList.firstWhere(
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
}

class SearchableDropdown extends StatelessWidget {
  final List<DropdownMenuItem<String>> items;
  final String? value;
  final Widget hint;
  final String searchHint;
  final ValueChanged<String?> onChanged;
  final bool isExpanded;
  final bool dialogBox;
  final BoxConstraints menuConstraints;
  final String closeButton;
  final bool displayClearIcon;
  final TextStyle style;
  final Widget underline;
  final Widget icon;
  final double iconSize;
  final Color iconEnabledColor;
  final Color iconDisabledColor;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.value,
    required this.hint,
    required this.searchHint,
    required this.onChanged,
    this.isExpanded = false,
    this.dialogBox = false,
    required this.menuConstraints,
    required this.closeButton,
    this.displayClearIcon = false,
    required this.style,
    required this.underline,
    required this.icon,
    required this.iconSize,
    required this.iconEnabledColor,
    required this.iconDisabledColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Show search dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return SearchDialog(
                items: items,
                searchHint: searchHint,
                closeButton: closeButton,
                onSelected: (selectedValue) {
                  onChanged(selectedValue);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // For extremely narrow widths, show only the icon
            if (constraints.maxWidth < 100) {
              return Center(child: icon);
            }

            // For normal widths, show the full row
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child:
                      value == null
                          ? hint
                          : Text(
                            value!,
                            style: style,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                ),
                const SizedBox(width: 4),
                icon,
              ],
            );
          },
        ),
      ),
    );
  }
}

class SearchDialog extends StatefulWidget {
  final List<DropdownMenuItem<String>> items;
  final String searchHint;
  final String closeButton;
  final Function(String?) onSelected;

  const SearchDialog({
    super.key,
    required this.items,
    required this.searchHint,
    required this.closeButton,
    required this.onSelected,
  });

  @override
  SearchDialogState createState() => SearchDialogState();
}

class SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<DropdownMenuItem<String>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems =
            widget.items
                .where(
                  (item) =>
                      (item.value?.toLowerCase().contains(query) ?? false),
                )
                .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Select Knowledge Base',
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
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
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
              ),
            ),
            const SizedBox(height: 16),

            // List of Items
            Flexible(
              child:
                  _filteredItems.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No results found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: InkWell(
                              onTap: () {
                                widget.onSelected(_filteredItems[index].value);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.library_books_outlined,
                                      color: Color(0xFF3B5998),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DefaultTextStyle(
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        child: _filteredItems[index].child,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),

            // Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B5998),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(widget.closeButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
