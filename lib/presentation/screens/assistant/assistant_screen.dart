import 'package:flutter/material.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/assistant.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/new_button_widget.dart';
import 'package:amd_chat_ai/service/assistant_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  bool showFavoritesOnly = false;
  bool isPublishedSelected = false;
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();

  // Sort options
  String _sortField = 'createdAt'; // Default sort by created date
  String _sortOrder = 'DESC'; // Default newest first

  final AssistantService _assistantService = AssistantService();
  List<Assistant> _assistants = [];
  int _currentOffset = 0;
  final int _limit = 10;
  bool _hasMoreAssistants = true;
  int _totalAssistants = 0;

  // Focus node to detect when screen regains focus
  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkUserAndLoadAssistants();

    // Add a listener to reload data when the screen regains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.addListener(() {
        if (_screenFocusNode.hasFocus) {
          debugPrint('Assistant screen regained focus, refreshing data');
          _loadAssistants(refresh: true);
        }
      });
      // Request focus to trigger the listener
      _screenFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkUserAndLoadAssistants() async {
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

    // User is logged in, load assistants
    _loadAssistants();
  }

  // Handle search text changes
  void _handleSearchChanged(String value) {
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        debugPrint('Search query: $value');
        _loadAssistants(refresh: true);
      }
    });
  }

  Future<void> _loadAssistants({bool refresh = false}) async {
    debugPrint("Loading assistants - refresh: $refresh");
    if (refresh) {
      setState(() {
        _currentOffset = 0;
        _hasMoreAssistants = true;
        _isLoading = true;
        _hasError = false;
      });
    } else if (!_hasMoreAssistants || _isLoading) {
      return;
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      debugPrint(
        "Making API call to fetch assistants with offset: $_currentOffset",
      );
      final searchQuery = _searchController.text.trim();
      final response = await _assistantService.getAssistants(
        offset: _currentOffset,
        limit: _limit,
        isFavorite: showFavoritesOnly ? true : null,
        isPublished: isPublishedSelected ? true : null,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        orderField: _sortField,
        order: _sortOrder,
      );

      if (response != null) {
        debugPrint(
          "API response received: ${response.items.length} items, hasNext: ${response.hasNext}",
        );
        setState(() {
          if (refresh || _currentOffset == 0) {
            _assistants = response.items;
          } else {
            _assistants.addAll(response.items);
          }
          _hasMoreAssistants = response.hasNext;
          _currentOffset += response.items.length;
          _totalAssistants =
              response.total > 0 ? response.total : _assistants.length;
          debugPrint(
            "Updated offset to: $_currentOffset, total from API: ${response.total}, using: $_totalAssistants",
          );
          _isLoading = false;
        });
        debugPrint("Updated state: ${_assistants.length} total assistants");
      } else {
        debugPrint("API response is null");
        setState(() {
          _hasError = true;
          _isLoading = false;
          _totalAssistants = 0; // Reset total count on error
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _totalAssistants = 0; // Reset total count on error
      });
      debugPrint('Error loading assistants: $e');
    }
  }

  Future<void> _toggleFavorite(String assistantId, bool currentStatus) async {
    debugPrint(
      'AssistantScreen: Toggling favorite for assistant $assistantId, current status: $currentStatus',
    );

    // Find the assistant
    final assistantIndex = _assistants.indexWhere((p) => p.id == assistantId);
    if (assistantIndex == -1) return;

    final assistant = _assistants[assistantIndex];

    // Optimistically update UI
    setState(() {
      final updatedAssistant = Assistant(
        id: assistant.id,
        assistantName: assistant.assistantName,
        description: assistant.description,
        instructions: assistant.instructions,
        userId: assistant.userId,
        isDefault: assistant.isDefault,
        isFavorite: !currentStatus,
        createdAt: assistant.createdAt,
        updatedAt: assistant.updatedAt,
        permissions: assistant.permissions,
      );
      _assistants[assistantIndex] = updatedAssistant;
      debugPrint(
        'AssistantScreen: UI updated optimistically, new favorite status: ${!currentStatus}',
      );
    });

    // Call API to update favorite status
    try {
      debugPrint(
        'AssistantScreen: Calling API to toggle favorite status to ${!currentStatus}',
      );
      final success = await _assistantService.toggleFavorite(
        assistantId,
        !currentStatus,
      );

      if (success) {
        debugPrint('AssistantScreen: Successfully toggled favorite status');
        // If we're showing favorites only and we just unfavorited an item, refresh the list
        if (showFavoritesOnly && currentStatus) {
          debugPrint(
            'AssistantScreen: Refreshing list after unfavoriting in favorites view',
          );
          _loadAssistants(refresh: true);
        }
      } else {
        debugPrint('AssistantScreen: Failed to toggle favorite status');
        // If API call fails, revert the UI change
        setState(() {
          final updatedAssistant = Assistant(
            id: assistant.id,
            assistantName: assistant.assistantName,
            description: assistant.description,
            instructions: assistant.instructions,
            userId: assistant.userId,
            isDefault: assistant.isDefault,
            isFavorite: currentStatus,
            createdAt: assistant.createdAt,
            updatedAt: assistant.updatedAt,
            permissions: assistant.permissions,
          );
          _assistants[assistantIndex] = updatedAssistant;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update favorite status')),
          );
        }
      }
    } catch (e) {
      // If an exception occurs, revert the UI change
      setState(() {
        final updatedAssistant = Assistant(
          id: assistant.id,
          assistantName: assistant.assistantName,
          description: assistant.description,
          instructions: assistant.instructions,
          userId: assistant.userId,
          isDefault: assistant.isDefault,
          isFavorite: currentStatus,
          createdAt: assistant.createdAt,
          updatedAt: assistant.updatedAt,
          permissions: assistant.permissions,
        );
        _assistants[assistantIndex] = updatedAssistant;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite status: $e')),
        );
      }
    }
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
                      'Delete Assistant',
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
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deleteAssistant(itemId, itemName);
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

  // Method to handle deleting an assistant
  Future<void> _deleteAssistant(
    String assistantId,
    String assistantName,
  ) async {
    try {
      final success = await _assistantService.deleteAssistant(assistantId);

      if (success) {
        setState(() {
          _assistants.removeWhere((p) => p.id == assistantId);
          _totalAssistants--;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$assistantName deleted')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete assistant')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting assistant: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _screenFocusNode,
      child: BaseScreen(
        title: 'Assistant',
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // New Assistant button and search bar row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search Assistant',
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
                    onTap: () {
                      Navigator.of(context).pushNamed('/create-assistant');
                    },
                    label: 'New',
                    icon: Icons.add_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter options
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    // Favorites filter
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showFavoritesOnly = !showFavoritesOnly;
                        });
                        // Reload data with new filter
                        _loadAssistants(refresh: true);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              showFavoritesOnly
                                  ? const Color(0xFF415DF2)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              showFavoritesOnly
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color:
                                  showFavoritesOnly
                                      ? Colors.white
                                      : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Favorites',
                              style: TextStyle(
                                color:
                                    showFavoritesOnly
                                        ? Colors.white
                                        : Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Published/Unpublished filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IntrinsicHeight(),
                    ),

                    // Sort options dropdown
                    PopupMenuButton<Map<String, String>>(
                      tooltip: 'Sort options',
                      onSelected: (Map<String, String> item) {
                        setState(() {
                          _sortField = item['field']!;
                          _sortOrder = item['order']!;
                        });
                        _loadAssistants(refresh: true);
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: {'field': 'createdAt', 'order': 'DESC'},
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color:
                                        _sortField == 'createdAt' &&
                                                _sortOrder == 'DESC'
                                            ? const Color(0xFF415DF2)
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Newest first'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: {'field': 'createdAt', 'order': 'ASC'},
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color:
                                        _sortField == 'createdAt' &&
                                                _sortOrder == 'ASC'
                                            ? const Color(0xFF415DF2)
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Oldest first'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: {'field': 'assistantName', 'order': 'ASC'},
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sort_by_alpha,
                                    size: 16,
                                    color:
                                        _sortField == 'assistantName' &&
                                                _sortOrder == 'ASC'
                                            ? const Color(0xFF415DF2)
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Name (A-Z)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: {
                                'field': 'assistantName',
                                'order': 'DESC',
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sort_by_alpha,
                                    size: 16,
                                    color:
                                        _sortField == 'assistantName' &&
                                                _sortOrder == 'DESC'
                                            ? const Color(0xFF415DF2)
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Name (Z-A)'),
                                ],
                              ),
                            ),
                          ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortField == 'createdAt'
                                  ? _sortOrder == 'DESC'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward
                                  : Icons.sort_by_alpha,
                              size: 16,
                              color: const Color(0xFF415DF2),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sortField == 'createdAt'
                                  ? _sortOrder == 'DESC'
                                      ? 'Newest'
                                      : 'Oldest'
                                  : _sortOrder == 'ASC'
                                  ? 'A-Z'
                                  : 'Z-A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF415DF2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Assistant count
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Text(
                      '$_totalAssistants Assistants Available',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Assistant list
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
                                ' assistants',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadAssistants(refresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : _isLoading && _assistants.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _assistants.isEmpty
                        ? Center(
                          child: Text(
                            showFavoritesOnly
                                ? 'No favorite assistants yet'
                                : 'No assistants available',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () => _loadAssistants(refresh: true),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  !_isLoading &&
                                  _hasMoreAssistants) {
                                _loadAssistants();
                                return true;
                              }
                              return false;
                            },
                            child: ListView.separated(
                              itemCount:
                                  _assistants.length +
                                  (_hasMoreAssistants ? 1 : 0),
                              separatorBuilder:
                                  (context, index) => const Divider(
                                    height: 1,
                                    color: Color(0xFFEEEEEE),
                                  ),
                              itemBuilder: (context, index) {
                                // Show loading indicator at the bottom when loading more items
                                if (index == _assistants.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final assistant = _assistants[index];
                                // Generate random color based on name
                                final int colorValue =
                                    assistant.assistantName.hashCode;
                                final Color avatarColor = Color.fromARGB(
                                  204, // 0.8 opacity (204/255)
                                  (colorValue & 0xFF0000) >> 16,
                                  (colorValue & 0x00FF00) >> 8,
                                  colorValue & 0x0000FF,
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        '/update-assistant',
                                        arguments: assistant,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: avatarColor,
                                          child: const Icon(
                                            Icons.smart_toy_outlined,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Name and description - with Expanded
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                assistant.assistantName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                assistant.description,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Action buttons
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Favorite button
                                            IconButton(
                                              icon: Icon(
                                                assistant.isFavorite
                                                    ? Icons.star_rounded
                                                    : Icons
                                                        .star_outline_rounded,
                                                color:
                                                    assistant.isFavorite
                                                        ? Colors.amber
                                                        : Colors.grey,
                                              ),
                                              onPressed:
                                                  () => _toggleFavorite(
                                                    assistant.id,
                                                    assistant.isFavorite,
                                                  ),
                                              tooltip:
                                                  assistant.isFavorite
                                                      ? 'Remove from favorites'
                                                      : 'Add to favorites',
                                            ),
                                            // Chat button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.chat_bubble_outline,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pushNamed(
                                                  '/chat-ai',
                                                  arguments: {
                                                    'assistant': assistant,
                                                  },
                                                );
                                              },
                                              tooltip:
                                                  'Chat with this assistant',
                                            ),
                                            // Delete button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed:
                                                  () => _showDeleteConfirmation(
                                                    context,
                                                    assistant.assistantName,
                                                    assistant.id,
                                                  ),
                                              tooltip: 'Delete assistant',
                                            ),
                                          ],
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
