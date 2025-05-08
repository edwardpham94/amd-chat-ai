import 'package:flutter/material.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/prompt.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/base_screen.dart';
import 'package:amd_chat_ai/presentation/screens/widgets/new_button_widget.dart';
import 'package:amd_chat_ai/service/prompt_service.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  bool isPrivateSelected = true;
  bool showFavoritesOnly = false;
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();

  // Category filter
  String? _selectedCategory;
  final List<String> _categories = [
    'All',
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

  final PromptService _promptService = PromptService();
  List<Prompt> _prompts = [];
  int _currentOffset = 0;
  final int _limit = 10;
  bool _hasMorePrompts = true;
  int _totalPrompts = 0; // Total number of prompts available

  // Focus node to detect when screen regains focus
  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'All';
    _checkUserAndLoadPrompts();

    // Add a listener to reload data when the screen regains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.addListener(() {
        if (_screenFocusNode.hasFocus) {
          debugPrint('Prompt screen regained focus, refreshing data');
          _loadPrompts(refresh: true);
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

  Future<void> _checkUserAndLoadPrompts() async {
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

    // User is logged in, load prompts
    _loadPrompts();
  }

  // Handle search text changes
  void _handleSearchChanged(String value) {
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        debugPrint('Search query: $value');
        _loadPrompts(refresh: true);
      }
    });
  }

  // Handle category selection
  void _handleCategoryChanged(String? newValue) {
    setState(() {
      _selectedCategory = newValue;
    });
    debugPrint('Selected category: $newValue');
    _loadPrompts(refresh: true);
  }

  Future<void> _loadPrompts({bool refresh = false}) async {
    debugPrint("Loading prompts - refresh: $refresh");
    if (refresh) {
      setState(() {
        _currentOffset = 0;
        _hasMorePrompts = true;
        _isLoading = true;
        _hasError = false;
      });
    } else if (!_hasMorePrompts || _isLoading) {
      return;
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      debugPrint(
        "Making API call to fetch prompts with offset: $_currentOffset",
      );
      final searchQuery = _searchController.text.trim();
      final response = await _promptService.getPrompts(
        offset: _currentOffset,
        limit: _limit,
        isPublic: !isPrivateSelected,
        isFavorite: showFavoritesOnly ? true : null,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        category:
            (_selectedCategory != null && _selectedCategory != 'All')
                ? _selectedCategory
                : null,
      );

      if (response != null) {
        debugPrint(
          "API response received: ${response.items.length} items, hasNext: ${response.hasNext}",
        );
        setState(() {
          if (refresh || _currentOffset == 0) {
            _prompts = response.items;
          } else {
            _prompts.addAll(response.items);
          }
          _hasMorePrompts = response.hasNext;
          _currentOffset += response.items.length;
          _totalPrompts = response.total > 0 ? response.total : _prompts.length;
          debugPrint(
            "Updated offset to: $_currentOffset, total from API: ${response.total}, using: $_totalPrompts",
          );
          _isLoading = false;
        });
        debugPrint("Updated state: ${_prompts.length} total prompts");
      } else {
        debugPrint("API response is null");
        setState(() {
          _hasError = true;
          _isLoading = false;
          _totalPrompts = 0; // Reset total count on error
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _totalPrompts = 0; // Reset total count on error
      });
      debugPrint('Error loading prompts: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, String itemName) {
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
                      'Delete Prompt',
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
                              // Find the prompt ID by title
                              final promptId =
                                  _prompts
                                      .firstWhere(
                                        (p) => p.title == itemName,
                                        orElse:
                                            () => Prompt(
                                              id: '',
                                              title: '',
                                              content: '',
                                              description: '',
                                              category: '',
                                              language: '',
                                              isPublic: false,
                                              isFavorite: false,
                                              userId: '',
                                              userName: '',
                                              createdAt: DateTime.now(),
                                              updatedAt: DateTime.now(),
                                            ),
                                      )
                                      .id;

                              if (promptId.isNotEmpty) {
                                _deletePrompt(promptId, itemName);
                              } else {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not find prompt to delete',
                                    ),
                                    behavior: SnackBarBehavior.floating,
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

  Future<void> _toggleFavorite(String promptId, bool currentStatus) async {
    debugPrint(
      'PromptScreen: Toggling favorite for prompt $promptId, current status: $currentStatus',
    );

    // Optimistically update UI
    setState(() {
      final promptIndex = _prompts.indexWhere((p) => p.id == promptId);
      if (promptIndex != -1) {
        final updatedPrompt = Prompt(
          id: _prompts[promptIndex].id,
          title: _prompts[promptIndex].title,
          content: _prompts[promptIndex].content,
          description: _prompts[promptIndex].description,
          category: _prompts[promptIndex].category,
          language: _prompts[promptIndex].language,
          isPublic: _prompts[promptIndex].isPublic,
          isFavorite: !currentStatus,
          userId: _prompts[promptIndex].userId,
          userName: _prompts[promptIndex].userName,
          createdAt: _prompts[promptIndex].createdAt,
          updatedAt: _prompts[promptIndex].updatedAt,
        );
        _prompts[promptIndex] = updatedPrompt;
        debugPrint(
          'PromptScreen: UI updated optimistically, new favorite status: ${!currentStatus}',
        );
      }
    });

    // Call API to update favorite status
    try {
      debugPrint(
        'PromptScreen: Calling API to toggle favorite status to ${!currentStatus}',
      );
      final success = await _promptService.toggleFavorite(
        promptId,
        !currentStatus,
      );

      if (success) {
        debugPrint('PromptScreen: Successfully toggled favorite status');
        // If we're showing favorites only and we just unfavorited an item, refresh the list
        if (showFavoritesOnly && currentStatus) {
          debugPrint(
            'PromptScreen: Refreshing list after unfavoriting in favorites view',
          );
          _loadPrompts(refresh: true);
        }
      } else {
        debugPrint('PromptScreen: Failed to toggle favorite status');
        // If API call fails, revert the UI change
        setState(() {
          final promptIndex = _prompts.indexWhere((p) => p.id == promptId);
          if (promptIndex != -1) {
            final updatedPrompt = Prompt(
              id: _prompts[promptIndex].id,
              title: _prompts[promptIndex].title,
              content: _prompts[promptIndex].content,
              description: _prompts[promptIndex].description,
              category: _prompts[promptIndex].category,
              language: _prompts[promptIndex].language,
              isPublic: _prompts[promptIndex].isPublic,
              isFavorite: currentStatus,
              userId: _prompts[promptIndex].userId,
              userName: _prompts[promptIndex].userName,
              createdAt: _prompts[promptIndex].createdAt,
              updatedAt: _prompts[promptIndex].updatedAt,
            );
            _prompts[promptIndex] = updatedPrompt;
          }
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
        final promptIndex = _prompts.indexWhere((p) => p.id == promptId);
        if (promptIndex != -1) {
          final updatedPrompt = Prompt(
            id: _prompts[promptIndex].id,
            title: _prompts[promptIndex].title,
            content: _prompts[promptIndex].content,
            description: _prompts[promptIndex].description,
            category: _prompts[promptIndex].category,
            language: _prompts[promptIndex].language,
            isPublic: _prompts[promptIndex].isPublic,
            isFavorite: currentStatus,
            userId: _prompts[promptIndex].userId,
            userName: _prompts[promptIndex].userName,
            createdAt: _prompts[promptIndex].createdAt,
            updatedAt: _prompts[promptIndex].updatedAt,
          );
          _prompts[promptIndex] = updatedPrompt;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite status: $e')),
        );
      }
    }
  }

  // Method to handle deleting a prompt
  Future<void> _deletePrompt(String promptId, String promptTitle) async {
    Navigator.of(context).pop(); // Close the confirmation dialog

    try {
      final success = await _promptService.deletePrompt(promptId);

      if (success) {
        setState(() {
          _prompts.removeWhere((p) => p.id == promptId);
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$promptTitle deleted')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete prompt')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting prompt: $e')));
      }
    }
  }

  void _showPromptSelectionModal(String promptTitle, String promptDescription) {
    final TextEditingController inputController = TextEditingController();
    debugPrint(
      'Showing prompt modal - Title: $promptTitle, Content: $promptDescription',
    );

    // Show a simpler dialog that is guaranteed to close properly
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_objects_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        promptTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prompt section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prompt',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            promptDescription,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Input section
                    const Text(
                      'Your Input',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: inputController,
                      decoration: InputDecoration(
                        hintText: 'Add details to your prompt...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            final userInput = inputController.text.trim();
                            final formattedPrompt =
                                '#About Yourself: $promptDescription + \nMy Problem: $userInput';
                            Navigator.pop(dialogContext);

                            // Navigate to chat screen with the formatted prompt
                            // and a flag to send automatically
                            Navigator.pushNamed(
                              context,
                              '/chat-ai',
                              arguments: {
                                'prompt': formattedPrompt,
                                'sendImmediately': true,
                              },
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send, size: 16),
                              SizedBox(width: 8),
                              Text('Send'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter prompts based on current filters
    final displayedPrompts = _prompts;

    return Focus(
      focusNode: _screenFocusNode,
      child: BaseScreen(
        title: 'Prompt',
        showBackButton: true,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Search bar and New button row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search Prompts',
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
                  // New button using the NewButton widget
                  NewButton(
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/create-prompt',
                      );
                      // If prompt was created successfully, refresh the list
                      if (result == true && mounted) {
                        debugPrint('Prompt created, refreshing list');
                        _loadPrompts(refresh: true);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdown
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory ?? 'All',
                    hint: const Text('Select Category'),
                    icon: const Icon(Icons.arrow_drop_down),
                    elevation: 16,
                    style: const TextStyle(color: Colors.black87),
                    onChanged: _handleCategoryChanged,
                    items:
                        _categories.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                  ),
                ),
              ),

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
                        _loadPrompts(refresh: true);
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
                    // Private/Public filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPrivateSelected = true;
                                });
                                // Reload data with new filter
                                _loadPrompts(refresh: true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isPrivateSelected
                                          ? const Color(0xFF415DF2)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Private',
                                  style: TextStyle(
                                    color:
                                        isPrivateSelected
                                            ? Colors.white
                                            : Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPrivateSelected = false;
                                });
                                // Reload data with new filter
                                _loadPrompts(refresh: true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      !isPrivateSelected
                                          ? const Color(0xFF415DF2)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Public',
                                  style: TextStyle(
                                    color:
                                        !isPrivateSelected
                                            ? Colors.white
                                            : Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Prompt count
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Text(
                      '$_totalPrompts Prompts Available',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Prompt list
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
                                'Failed to load prompts',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadPrompts(refresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : _isLoading && _prompts.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : displayedPrompts.isEmpty
                        ? Center(
                          child: Text(
                            showFavoritesOnly
                                ? 'No favorite prompts yet'
                                : 'No prompts available',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () => _loadPrompts(refresh: true),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  !_isLoading &&
                                  _hasMorePrompts) {
                                _loadPrompts();
                                return true;
                              }
                              return false;
                            },
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount:
                                  displayedPrompts.length +
                                  (_hasMorePrompts ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at the bottom when loading more items
                                if (index == displayedPrompts.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final prompt = displayedPrompts[index];
                                final Color avatarColor =
                                    index % 2 == 0
                                        ? Colors.blue
                                        : Colors.purple;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(
                                          13,
                                        ), // 0.05 opacity
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
                                      prompt.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        prompt.description,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: avatarColor,
                                      child: Text(
                                        prompt.title.isNotEmpty
                                            ? prompt.title[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Favorite button
                                        IconButton(
                                          icon: Icon(
                                            prompt.isFavorite
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            color:
                                                prompt.isFavorite
                                                    ? Colors.amber
                                                    : Colors.grey,
                                          ),
                                          onPressed:
                                              () => _toggleFavorite(
                                                prompt.id,
                                                prompt.isFavorite,
                                              ),
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
                                                prompt.title,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            _showPromptSelectionModal(
                                              prompt.title,
                                              prompt.content,
                                            );
                                          },
                                          tooltip: 'Apply this prompt',
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      // Navigate to update prompt screen
                                      final result = await Navigator.of(
                                        context,
                                      ).pushNamed(
                                        '/update-prompt',
                                        arguments: {
                                          'id': prompt.id,
                                          'title': prompt.title,
                                          'content': prompt.content,
                                          'description': prompt.description,
                                          'category': prompt.category,
                                          'language': prompt.language,
                                          'isPublic': prompt.isPublic,
                                          'userId': prompt.userId,
                                        },
                                      );

                                      // If prompt was updated successfully, refresh the list
                                      if (result == true && mounted) {
                                        debugPrint(
                                          'Prompt updated, refreshing list',
                                        );
                                        _loadPrompts(refresh: true);
                                      }
                                    },
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
