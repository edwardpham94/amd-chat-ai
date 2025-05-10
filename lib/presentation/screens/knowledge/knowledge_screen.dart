import 'package:amd_chat_ai/model/knowledge.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/new_button_widget.dart';
import 'package:amd_chat_ai/service/knowledge_service.dart';
import 'package:flutter/material.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  List<Knowledge> _knowledges = [];
  int _offset = 0;
  bool _hasNext = true;
  final KnowledgeService _knowledgeService = KnowledgeService();
  TextEditingController _searchController = TextEditingController();

  // List<Knowledge> knowledges = [];
  int _currentOffset = 0;
  final int _limit = 10;
  int _totalKnowledge = 0;
  bool _isLoading = true;
  bool _hasError = false;

  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.addListener(() {
        if (_screenFocusNode.hasFocus) {
          debugPrint('knowledge screen regained focus, refreshing data');
          _loadKnowledges(refresh: true);
        }
      });
      // Request focus to trigger the listener
      _screenFocusNode.requestFocus();
    });
  }

  void _handleSearchChanged(String value) {
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        debugPrint('Search query: $value');
        _loadKnowledges(refresh: true);
      }
    });
  }

  Future<void> _loadKnowledges({bool refresh = false}) async {
    debugPrint("Loading knowledges - refresh: $refresh");
    if (refresh) {
      setState(() {
        _offset = 0;
        _hasNext = true;
        _isLoading = true;
        _hasError = false;
      });
    } else if (!_hasNext || _isLoading) {
      return;
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      debugPrint(
        "Making API call to fetch knowledges with offset: $_currentOffset",
      );
      final searchQuery = _searchController.text.trim();
      final response = await _knowledgeService.getKnowledges(
        offset: _currentOffset,
        limit: _limit,
        q: searchQuery,
      );

      if (response != null) {
        debugPrint(
          "API response received: ${response.data.length} items, hasNext: ${response.meta.hasNext}",
        );
        setState(() {
          if (refresh || _currentOffset == 0) {
            _knowledges = response.data;
          } else {
            _knowledges.addAll(response.data);
          }
          _currentOffset += response.data.length;
          _totalKnowledge =
              response.meta.total > 0
                  ? response.meta.total
                  : _knowledges.length;
          debugPrint(
            "Updated offset to: $_currentOffset, total from API: ${response.meta.total}, using: $_totalKnowledge",
          );
          _isLoading = false;
        });
        debugPrint("Updated state: ${_knowledges.length} total knowledges");
      } else {
        debugPrint("API response is null");
        setState(() {
          _isLoading = false;
          _hasError = true;
          _totalKnowledge = 0; // Reset total count on error
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _totalKnowledge = 0; // Reset total count on error
      });
      debugPrint('Error loading knowledges: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedKnowledges = _knowledges;

    return Focus(
      focusNode: _screenFocusNode,
      child: BaseScreen(
        title: 'Knowledge',
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
                      decoration: InputDecoration(
                        hintText: 'Search Knowledge',
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
                  NewButton(
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/create-knowledge',
                      );
                      // If knowledge was created successfully, refresh the list
                      if (result == true && mounted) {
                        debugPrint('knowledge created, refreshing list');
                        _loadKnowledges(refresh: true);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Knowledge count
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Text(
                      '${_knowledges.length} Knowledge Available',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Knowledge list
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
                                'Failed to load knowledges',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadKnowledges(refresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : _isLoading && _knowledges.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: () => _loadKnowledges(refresh: true),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  !_isLoading &&
                                  _hasNext) {
                                _loadKnowledges();
                                return true;
                              }
                              return false;
                            },
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount:
                                  displayedKnowledges.length +
                                  (_hasNext ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == displayedKnowledges.length) {
                                  return _isLoading && _hasNext
                                      ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.0,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                      : const SizedBox.shrink();
                                }

                                final knowledge = displayedKnowledges[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      knowledge.knowledgeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        knowledge.description,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          index % 2 == 0
                                              ? Colors.blue
                                              : Colors.purple,
                                      child: Text(
                                        knowledge.knowledgeName.isNotEmpty
                                            ? knowledge.knowledgeName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _showDeleteConfirmation(
                                            context,
                                            knowledge.knowledgeName,
                                            knowledge.id ?? '',
                                          ),
                                    ),
                                    onTap: () async {
                                      final result = await Navigator.of(
                                        context,
                                      ).pushNamed(
                                        '/update-knowledge',
                                        arguments: {
                                          'id': knowledge.id,
                                          'knowledgeName':
                                              knowledge.knowledgeName,
                                          'description': knowledge.description,
                                        },
                                      );

                                      if (result == true && mounted) {
                                        _loadKnowledges(refresh: true);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
              )
            
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String itemName,
    String itemId,
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
                      'Delete Knowledge',
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
                              Navigator.of(context).pop();

                              final success = await _knowledgeService
                                  .deleteKnowledge(itemId);

                              if (success) {
                                setState(() {
                                  _knowledges.removeWhere(
                                    (item) => item.id == itemId,
                                  );
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$itemName deleted successfully',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete $itemName'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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

}
