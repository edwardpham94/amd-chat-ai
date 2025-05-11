import 'package:flutter/material.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/assistant.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/new_button_widget.dart';
import 'package:amd_chat_ai/service/assistant_service.dart';
import 'package:amd_chat_ai/service/knowledge_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
                                            // Publish button
                                            PopupMenuButton<String>(
                                              tooltip: 'Publish assistant',
                                              icon: const Icon(
                                                Icons.share_rounded,
                                                color: Color(0xFF415DF2),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              elevation: 4,
                                              offset: const Offset(0, 40),
                                              onSelected: (String platform) {
                                                // Handle publishing to selected platform
                                                switch (platform) {
                                                  case 'Slack':
                                                    _showSlackConfigModal(
                                                      context,
                                                      assistant.id,
                                                    );
                                                    break;
                                                  case 'Messenger':
                                                    _showMessengerConfigModal(
                                                      context,
                                                      assistant.id,
                                                    );
                                                    break;
                                                  case 'Telegram':
                                                    _showTelegramConfigModal(
                                                      context,
                                                      assistant.id,
                                                    );
                                                    break;
                                                }
                                              },
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                    PopupMenuItem<String>(
                                                      value: 'Slack',
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFE01E5A,
                                                                  ).withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: const Icon(
                                                              Icons
                                                                  .workspaces_filled,
                                                              color: Color(
                                                                0xFFE01E5A,
                                                              ),
                                                              size: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          const Text(
                                                            'Publish on Slack',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuItem<String>(
                                                      value: 'Messenger',
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFF0078FF,
                                                                  ).withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: const Icon(
                                                              Icons
                                                                  .messenger_outline_rounded,
                                                              color: Color(
                                                                0xFF0078FF,
                                                              ),
                                                              size: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          const Text(
                                                            'Messenger',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuItem<String>(
                                                      value: 'Telegram',
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFF0088CC,
                                                                  ).withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: const Icon(
                                                              Icons
                                                                  .telegram_rounded,
                                                              color: Color(
                                                                0xFF0088CC,
                                                              ),
                                                              size: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          const Text(
                                                            'Telegram',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                            ),
                                            // Chat button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.chat_bubble_outline,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pushNamed(
                                                  '/ask-assistant',
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

  void _showTelegramConfigModal(BuildContext context, String assistantId) {
    final TextEditingController botTokenController = TextEditingController();

    // Add listener to controller to enable/disable button
    ValueNotifier<bool> isFormValid = ValueNotifier<bool>(false);

    void validateForm() {
      isFormValid.value = botTokenController.text.trim().isNotEmpty;
    }

    botTokenController.addListener(validateForm);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Telegram icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0088CC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.telegram_rounded,
                          color: Color(0xFF0088CC),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Publish to Telegram',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bot Token field
                  const Text(
                    'Bot Token',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: botTokenController,
                    decoration: InputDecoration(
                      hintText: 'Enter your Telegram bot token',
                      prefixIcon: Icon(
                        Icons.key_rounded,
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0088CC)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isFormValid,
                      builder: (context, isValid, _) {
                        return ElevatedButton(
                          onPressed:
                              isValid
                                  ? () async {
                                    // Show loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Publishing to Telegram...',
                                        ),
                                      ),
                                    );

                                    // Call the API to publish the bot
                                    final knowledgeService = KnowledgeService();
                                    final result = await knowledgeService
                                        .publishTelegramBot(
                                          assistantId: assistantId,
                                          botToken:
                                              botTokenController.text.trim(),
                                        );

                                    // Close the modal
                                    Navigator.pop(context);

                                    // Show success or error message
                                    if (result['success'] == true) {
                                      final String redirectUrl =
                                          result['redirect'] ?? '';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Successfully published to Telegram',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (redirectUrl.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                GestureDetector(
                                                  onTap: () async {
                                                    final Uri url = Uri.parse(
                                                      redirectUrl,
                                                    );
                                                    if (await canLaunchUrl(
                                                      url,
                                                    )) {
                                                      await launchUrl(url);
                                                    }
                                                  },
                                                  child: Text(
                                                    'Bot URL: $redirectUrl',
                                                    style: const TextStyle(
                                                      decoration:
                                                          TextDecoration
                                                              .underline,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to publish to Telegram',
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0088CC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: const Color(
                              0xFF0088CC,
                            ).withOpacity(0.3),
                            disabledForegroundColor: Colors.white70,
                          ),
                          child: const Text(
                            'Publish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showMessengerConfigModal(BuildContext context, String assistantId) {
    final TextEditingController botTokenController = TextEditingController();
    final TextEditingController pageIdController = TextEditingController();
    final TextEditingController appSecretController = TextEditingController();

    // Add listeners to controllers to enable/disable button
    ValueNotifier<bool> isFormValid = ValueNotifier<bool>(false);

    void validateForm() {
      isFormValid.value =
          botTokenController.text.trim().isNotEmpty &&
          pageIdController.text.trim().isNotEmpty &&
          appSecretController.text.trim().isNotEmpty;
    }

    botTokenController.addListener(validateForm);
    pageIdController.addListener(validateForm);
    appSecretController.addListener(validateForm);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Messenger icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0078FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.messenger_outline_rounded,
                          color: Color(0xFF0078FF),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Publish to Messenger',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form fields
                  const Text(
                    'Bot Token',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: botTokenController,
                    decoration: InputDecoration(
                      hintText: 'Enter your Messenger bot token',
                      prefixIcon: Icon(
                        Icons.key_rounded,
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0078FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Page ID',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pageIdController,
                    decoration: InputDecoration(
                      hintText: 'Enter your Facebook Page ID',
                      prefixIcon: Icon(
                        Icons.pages_rounded,
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0078FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'App Secret',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: appSecretController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter your app secret',
                      prefixIcon: Icon(
                        Icons.security_rounded,
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0078FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isFormValid,
                      builder: (context, isValid, _) {
                        return ElevatedButton(
                          onPressed:
                              isValid
                                  ? () async {
                                    // Show loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Publishing to Messenger...',
                                        ),
                                      ),
                                    );

                                    // Call the API to publish the bot
                                    final knowledgeService = KnowledgeService();
                                    final result = await knowledgeService
                                        .publishMessengerBot(
                                          assistantId: assistantId,
                                          botToken:
                                              botTokenController.text.trim(),
                                          pageId: pageIdController.text.trim(),
                                          appSecret:
                                              appSecretController.text.trim(),
                                        );

                                    // Close the modal
                                    Navigator.pop(context);

                                    // Show success or error message
                                    if (result['success'] == true) {
                                      final String redirectUrl =
                                          result['redirect'] ?? '';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Successfully published to Messenger',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (redirectUrl.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                GestureDetector(
                                                  onTap: () async {
                                                    final Uri url = Uri.parse(
                                                      redirectUrl,
                                                    );
                                                    if (await canLaunchUrl(
                                                      url,
                                                    )) {
                                                      await launchUrl(url);
                                                    }
                                                  },
                                                  child: Text(
                                                    'Bot URL: $redirectUrl',
                                                    style: const TextStyle(
                                                      decoration:
                                                          TextDecoration
                                                              .underline,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to publish to Messenger',
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0078FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: const Color(
                              0xFF0078FF,
                            ).withOpacity(0.3),
                            disabledForegroundColor: Colors.white70,
                          ),
                          child: const Text(
                            'Publish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showSlackConfigModal(BuildContext context, String assistantId) {
    final TextEditingController botTokenController = TextEditingController();
    final TextEditingController clientIdController = TextEditingController();
    final TextEditingController clientSecretController =
        TextEditingController();
    final TextEditingController signingSecretController =
        TextEditingController();

    // Add listeners to controllers to enable/disable button
    ValueNotifier<bool> isFormValid = ValueNotifier<bool>(false);

    void validateForm() {
      isFormValid.value =
          botTokenController.text.trim().isNotEmpty &&
          clientIdController.text.trim().isNotEmpty &&
          clientSecretController.text.trim().isNotEmpty &&
          signingSecretController.text.trim().isNotEmpty;
    }

    botTokenController.addListener(validateForm);
    clientIdController.addListener(validateForm);
    clientSecretController.addListener(validateForm);
    signingSecretController.addListener(validateForm);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Slack icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE01E5A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.diversity_3,
                            color: Color(0xFFE01E5A),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Publish to Slack',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Form fields
                    const Text(
                      'Bot Token',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: botTokenController,
                      decoration: InputDecoration(
                        hintText: 'Enter your Slack bot token',
                        prefixIcon: Icon(
                          Icons.key_rounded,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE01E5A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Client ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: clientIdController,
                      decoration: InputDecoration(
                        hintText: 'Enter your Slack client ID',
                        prefixIcon: Icon(
                          Icons.app_registration_rounded,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE01E5A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Client Secret',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: clientSecretController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter your Slack client secret',
                        prefixIcon: Icon(
                          Icons.vpn_key_rounded,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE01E5A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Signing Secret',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: signingSecretController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter your Slack signing secret',
                        prefixIcon: Icon(
                          Icons.security_rounded,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE01E5A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isFormValid,
                        builder: (context, isValid, _) {
                          return ElevatedButton(
                            onPressed:
                                isValid
                                    ? () {
                                      // Process the submission
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Publishing to Slack...',
                                          ),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE01E5A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: const Color(
                                0xFFE01E5A,
                              ).withOpacity(0.3),
                              disabledForegroundColor: Colors.white70,
                            ),
                            child: const Text(
                              'Publish',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
