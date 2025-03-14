import 'package:flutter/material.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/primary_button.dart';

class CreateAssistantScreen extends StatefulWidget {
  const CreateAssistantScreen({super.key});

  @override
  State<CreateAssistantScreen> createState() => _CreateAssistantScreenState();
}

class _CreateAssistantScreenState extends State<CreateAssistantScreen> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedKnowledge;

  // Sample knowledge data - Replace with your actual knowledge list
  final List<String> _knowledgeList = [
    'Company Policy Knowledge',
    'Product Documentation',
    'Customer Support FAQ',
    'Technical Documentation',
    'HR Guidelines',
    'Marketing Materials',
    'Sales Playbooks',
    'Industry Research',
    'Competitor Analysis',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              _buildSectionTitle('Knowledge Base'),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState:
                    _selectedKnowledge == null
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                firstChild: Container(
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
                  child: SearchableDropdown(
                    items:
                        _knowledgeList.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                    value: _selectedKnowledge,
                    hint: LayoutBuilder(
                      builder: (context, constraints) {
                        // For extremely narrow widths, show only the icon
                        if (constraints.maxWidth < 100) {
                          return const Icon(
                            Icons.library_books_outlined,
                            color: Color(0xFF3B5998),
                            size: 20,
                          );
                        }

                        // For normal widths, show the full row
                        return const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              color: Color(0xFF3B5998),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select Knowledge Base',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    searchHint: 'Search Knowledge Base',
                    onChanged: (value) {
                      setState(() {
                        _selectedKnowledge = value;
                      });
                    },
                    isExpanded: true,
                    dialogBox: true,
                    menuConstraints: BoxConstraints.tight(
                      const Size.fromHeight(350),
                    ),
                    closeButton: 'Close',
                    displayClearIcon: true,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    underline: Container(height: 0, color: Colors.transparent),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF3B5998).withAlpha(77),
                      size: 28,
                    ),
                    iconSize: 24,
                    iconEnabledColor: const Color(0xFF3B5998),
                    iconDisabledColor: Colors.grey,
                  ),
                ),
                secondChild: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B5998).withAlpha(5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B5998).withAlpha(10),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // For extremely narrow widths, show only the icon
                      if (constraints.maxWidth < 100) {
                        return Center(
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedKnowledge = null;
                              });
                            },
                            icon: const Icon(
                              Icons.library_books_rounded,
                              color: Color(0xFF3B5998),
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        );
                      }

                      // For normal widths, show the full row
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B5998).withAlpha(5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.library_books_rounded,
                              color: Color(0xFF3B5998),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Selected Knowledge Base',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF3B5998),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedKnowledge ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedKnowledge = null;
                              });
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.black54,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
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
                child: PrimaryButton(
                  label: 'Create Assistant',
                  onPressed: () {
                    // Handle create assistant logic
                    final assistant = {
                      'name': _nameController.text,
                      'instructions': _instructionsController.text,
                      'description': _descriptionController.text,
                      'knowledge': _selectedKnowledge,
                    };

                    debugPrint('Created Assistant: $assistant');
                    Navigator.pop(context);
                  },
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
