import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/prompt.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PromptService {
  /// Fetches prompts from the API with optional filtering
  ///
  /// Parameters:
  /// - offset: Starting position for pagination
  /// - limit: Number of items to fetch
  /// - category: Optional category filter
  /// - isFavorite: Optional filter for favorite prompts
  /// - isPublic: Optional filter for public/private prompts
  Future<PromptResponse?> getPrompts({
    int offset = 0,
    int limit = 10,
    String? category,
    bool? isFavorite,
    bool? isPublic,
    String? searchQuery,
  }) async {
    try {
      debugPrint("PromptService: Starting getPrompts call");
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'offset': offset,
        'limit': limit,
      };

      // Add optional filters if provided
      if (category != null) {
        queryParams['category'] = category;
      }

      if (isFavorite != null) {
        queryParams['isFavorite'] = isFavorite;
      }

      if (isPublic != null) {
        queryParams['isPublic'] = isPublic;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['query'] = searchQuery;
      }

      // Get user ID for the header
      final userId = await UserStorage.getUserId();
      final accessToken = await UserStorage.getAccessToken();
      debugPrint("PromptService: User ID: $userId");
      debugPrint("PromptService: Access Token: $accessToken");
      // Make the API request
      final fullUrl =
          '${DioClients.jarvisClient.options.baseUrl}/api/v1/prompts';
      debugPrint('PromptService: Making request to $fullUrl');
      debugPrint('PromptService: Query parameters: $queryParams');

      final response = await DioClients.jarvisClient.get(
        '/api/v1/prompts',
        queryParameters: queryParams,
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'PromptService: Response received with status code: ${response.statusCode}',
      );
      debugPrint('PromptService: Response data: ${response.data}');

      // Parse the response
      final promptResponse = PromptResponse.fromJson(response.data);
      return promptResponse;
    } on DioException catch (e) {
      debugPrint(
        'PromptService: Error fetching prompts: ${e.response?.data ?? e.message}',
      );
      return null;
    }
  }

  /// Toggles the favorite status of a prompt
  Future<bool> toggleFavorite(String promptId, bool isFavorite) async {
    try {
      final userId = await UserStorage.getUserId();
      debugPrint(
        'PromptService: Toggling favorite status for prompt $promptId to $isFavorite',
      );

      if (isFavorite) {
        // Add to favorites
        debugPrint('PromptService: Adding prompt $promptId to favorites');
        final response = await DioClients.jarvisClient.post(
          '/api/v1/prompts/$promptId/favorite',
          options: Options(headers: {'x-jarvis-guid': userId}),
        );
        debugPrint(
          'PromptService: Add to favorites response status: ${response.statusCode}',
        );
      } else {
        // Remove from favorites
        debugPrint('PromptService: Removing prompt $promptId from favorites');
        final response = await DioClients.jarvisClient.delete(
          '/api/v1/prompts/$promptId/favorite',
          options: Options(headers: {'x-jarvis-guid': userId}),
        );
        debugPrint(
          'PromptService: Remove from favorites response status: ${response.statusCode}',
        );
      }

      return true;
    } on DioException catch (e) {
      debugPrint(
        'PromptService: Error toggling favorite: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  /// Deletes a prompt
  Future<bool> deletePrompt(String promptId) async {
    try {
      final userId = await UserStorage.getUserId();

      await DioClients.jarvisClient.delete(
        '/api/v1/prompts/$promptId',
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        'PromptService: Error deleting prompt: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  /// Updates a prompt
  ///
  /// API: PATCH /api/v1/prompts/{id}
  /// Required fields: category, description, isPublic, language
  /// Optional fields: title, content
  Future<bool> updatePrompt({
    required String promptId,
    String? title,
    String? content,
    required String description,
    required String category,
    required String language,
    required bool isPublic,
  }) async {
    try {
      final userId = await UserStorage.getUserId();
      debugPrint('PromptService: Updating prompt $promptId');

      // Build request body with required fields
      final Map<String, dynamic> data = {
        'category': category,
        'description': description,
        'language': language,
        'isPublic': isPublic,
      };

      // Add optional fields if provided
      if (title != null && title.isNotEmpty) {
        data['title'] = title;
      }

      if (content != null && content.isNotEmpty) {
        data['content'] = content;
      }

      debugPrint('PromptService: Update request data: $data');

      final response = await DioClients.jarvisClient.patch(
        '/api/v1/prompts/$promptId',
        data: data,
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'PromptService: Update prompt response status: ${response.statusCode}',
      );
      return true;
    } on DioException catch (e) {
      debugPrint(
        'PromptService: Error updating prompt: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  /// Creates a new prompt
  ///
  /// API: POST /api/v1/prompts
  /// Required fields: category, content, description, isPublic, language, title
  Future<bool> createPrompt({
    required String title,
    required String content,
    required String description,
    required String category,
    required String language,
    required bool isPublic,
  }) async {
    try {
      final userId = await UserStorage.getUserId();
      debugPrint('PromptService: Creating new prompt');

      // Build request body with all required fields
      final Map<String, dynamic> data = {
        'title': title,
        'content': content,
        'description': description,
        'category': category,
        'language': language,
        'isPublic': isPublic,
      };

      debugPrint('PromptService: Create request data: $data');

      final response = await DioClients.jarvisClient.post(
        '/api/v1/prompts',
        data: data,
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'PromptService: Create prompt response status: ${response.statusCode}',
      );
      debugPrint('PromptService: Create prompt response: ${response.data}');
      return true;
    } on DioException catch (e) {
      debugPrint(
        'PromptService: Error creating prompt: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }
}
