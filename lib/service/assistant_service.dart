import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/assistant.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AssistantService {
  /// Fetches assistants from the API with optional filtering
  ///
  /// Parameters:
  /// - offset: Starting position for pagination
  /// - limit: Number of items to fetch
  /// - isFavorite: Optional filter for favorite assistants
  /// - isPublished: Optional filter for published/unpublished assistants
  /// - searchQuery: Optional search term
  /// - orderField: Field to sort by (e.g., 'createdAt', 'assistantName')
  /// - order: Sort direction ('ASC' or 'DESC')
  Future<AssistantResponse?> getAssistants({
    int offset = 0,
    int limit = 10,
    bool? isFavorite,
    bool? isPublished,
    String? searchQuery,
    String? orderField,
    String? order,
  }) async {
    try {
      debugPrint("AssistantService: Starting getAssistants call");

      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'offset': offset,
        'limit': limit,
      };

      // Add optional filters if provided
      if (isFavorite != null) {
        queryParams['is_favorite'] = isFavorite;
      }

      if (isPublished != null) {
        queryParams['is_published'] = isPublished;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }

      // Add sorting parameters if provided
      if (orderField != null && orderField.isNotEmpty) {
        queryParams['order_field'] = orderField;
      }

      if (order != null && order.isNotEmpty) {
        queryParams['order'] = order;
      }

      // Get user ID
      final userId = await UserStorage.getUserId();

      debugPrint("AssistantService: User ID: $userId");

      if (userId == null) {
        debugPrint('AssistantService: User not logged in');
        return null;
      }

      debugPrint(
        'AssistantService: Making request to /kb-core/v1/ai-assistant',
      );
      debugPrint('AssistantService: Query parameters: $queryParams');

      final response = await DioClients.kbClient.get(
        '/kb-core/v1/ai-assistant',
        queryParameters: queryParams,
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'AssistantService: Response received with status code: ${response.statusCode}',
      );
      debugPrint('AssistantService: Response data received');

      // Parse the response
      final assistantResponse = AssistantResponse.fromJson(response.data);
      debugPrint(
        'AssistantService: Fetched ${assistantResponse.items.length} assistants',
      );

      return assistantResponse;
    } on DioException catch (e) {
      debugPrint(
        'AssistantService: Error fetching assistants: ${e.response?.data ?? e.message}',
      );
      return null;
    } catch (e) {
      debugPrint('AssistantService: Unexpected error: $e');
      return null;
    }
  }

  /// Creates a new assistant
  ///
  /// Parameters:
  /// - assistantName: Name of the assistant
  /// - instructions: Instructions for the assistant
  /// - description: Description of the assistant
  Future<Assistant?> createAssistant({
    required String assistantName,
    required String instructions,
    required String description,
  }) async {
    try {
      final userId = await UserStorage.getUserId();

      if (userId == null) {
        debugPrint('AssistantService: User not logged in');
        return null;
      }

      debugPrint('AssistantService: Creating new assistant: $assistantName');

      final data = {
        'assistantName': assistantName,
        'instructions': instructions,
        'description': description,
      };

      final response = await DioClients.kbClient.post(
        '/kb-core/v1/ai-assistant',
        data: data,
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'AssistantService: Create assistant response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final assistant = Assistant.fromJson(response.data);
          debugPrint(
            'AssistantService: Successfully created assistant with ID: ${assistant.id}',
          );
          return assistant;
        } catch (parseError) {
          debugPrint(
            'AssistantService: Error parsing assistant data: $parseError',
          );
          debugPrint('AssistantService: Response data: ${response.data}');

          // If we can't parse the full response but have an ID, create a minimal valid assistant object
          if (response.data != null && response.data['id'] != null) {
            return Assistant(
              id: response.data['id'] as String,
              assistantName:
                  response.data['assistantName'] as String? ?? assistantName,
              description:
                  response.data['description'] as String? ?? description,
              instructions:
                  response.data['instructions'] as String? ?? instructions,
              userId: response.data['userId'] as String? ?? userId,
              isDefault: response.data['isDefault'] as bool? ?? false,
              isFavorite: response.data['isFavorite'] as bool? ?? false,
              createdAt:
                  response.data['createdAt'] != null
                      ? DateTime.parse(response.data['createdAt'] as String)
                      : DateTime.now(),
              updatedAt:
                  response.data['updatedAt'] != null
                      ? DateTime.parse(response.data['updatedAt'] as String)
                      : DateTime.now(),
              permissions: [],
            );
          }
          return null;
        }
      } else {
        return null;
      }
    } on DioException catch (e) {
      debugPrint(
        'AssistantService: Error creating assistant: ${e.response?.data ?? e.message}',
      );
      return null;
    } catch (e) {
      debugPrint('AssistantService: Unexpected error: $e');
      return null;
    }
  }

  /// Toggles the favorite status of an assistant
  Future<bool> toggleFavorite(String assistantId, bool isFavorite) async {
    try {
      final userId = await UserStorage.getUserId();

      if (userId == null) {
        debugPrint('AssistantService: User not logged in');
        return false;
      }

      debugPrint(
        'AssistantService: Toggling favorite status for assistant $assistantId to $isFavorite',
      );

      final response = await DioClients.kbClient.post(
        '/kb-core/v1/ai-assistant/$assistantId/favorite',
        data: {'is_favorite': isFavorite},
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'AssistantService: Update favorite response status: ${response.statusCode}',
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        'AssistantService: Error toggling favorite: ${e.response?.data ?? e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('AssistantService: Unexpected error: $e');
      return false;
    }
  }

  /// Deletes an assistant
  Future<bool> deleteAssistant(String assistantId) async {
    try {
      final userId = await UserStorage.getUserId();

      if (userId == null) {
        debugPrint('AssistantService: User not logged in');
        return false;
      }

      debugPrint('AssistantService: Deleting assistant $assistantId');

      final response = await DioClients.kbClient.delete(
        '/kb-core/v1/ai-assistant/$assistantId',
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'AssistantService: Delete assistant response status: ${response.statusCode}',
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        'AssistantService: Error deleting assistant: ${e.response?.data ?? e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('AssistantService: Unexpected error: $e');
      return false;
    }
  }

  /// Updates the published status of an assistant
  Future<bool> togglePublished(String assistantId, bool isPublished) async {
    try {
      final userId = await UserStorage.getUserId();

      if (userId == null) {
        debugPrint('AssistantService: User not logged in');
        return false;
      }

      debugPrint(
        'AssistantService: Toggling published status for assistant $assistantId to $isPublished',
      );

      final response = await DioClients.kbClient.put(
        '/kb-core/v1/ai-assistant/$assistantId/publish',
        data: {'is_published': isPublished},
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'AssistantService: Update published response status: ${response.statusCode}',
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        'AssistantService: Error toggling published: ${e.response?.data ?? e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('AssistantService: Unexpected error: $e');
      return false;
    }
  }

  /// Updates an existing assistant
  ///
  /// Parameters:
  /// - assistantId: ID of the assistant to update
  /// - assistantName: Name of the assistant
  /// - instructions: Instructions for the assistant
  /// - description: Description of the assistant
  Future<Assistant?> updateAssistant({
    required String assistantId,
    required String assistantName,
    required String instructions,
    required String description,
  }) async {
    try {
      final userId = await UserStorage.getUserId();

      if (userId == null) {
        debugPrint('AssistantService: User not logged in');
        return null;
      }

      debugPrint('AssistantService: Updating assistant: $assistantId');

      final data = {
        'assistantName': assistantName,
        'instructions': instructions,
        'description': description,
      };

      final response = await DioClients.kbClient.patch(
        '/kb-core/v1/ai-assistant/$assistantId',
        data: data,
        options: Options(headers: {'x-jarvis-guid': userId}),
      );

      debugPrint(
        'AssistantService: Update assistant response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final assistant = Assistant.fromJson(response.data);
          debugPrint(
            'AssistantService: Successfully updated assistant with ID: ${assistant.id}',
          );
          return assistant;
        } catch (parseError) {
          debugPrint(
            'AssistantService: Error parsing assistant data: $parseError',
          );
          debugPrint('AssistantService: Response data: ${response.data}');

          // If we can't parse the full response but have an ID, create a minimal valid assistant object
          if (response.data != null && response.data['id'] != null) {
            return Assistant(
              id: response.data['id'] as String? ?? assistantId,
              assistantName:
                  response.data['assistantName'] as String? ?? assistantName,
              description:
                  response.data['description'] as String? ?? description,
              instructions:
                  response.data['instructions'] as String? ?? instructions,
              userId: response.data['userId'] as String? ?? userId,
              isDefault: response.data['isDefault'] as bool? ?? false,
              isFavorite: response.data['isFavorite'] as bool? ?? false,
              createdAt:
                  response.data['createdAt'] != null
                      ? DateTime.parse(response.data['createdAt'] as String)
                      : DateTime.now(),
              updatedAt:
                  response.data['updatedAt'] != null
                      ? DateTime.parse(response.data['updatedAt'] as String)
                      : DateTime.now(),
              permissions: [],
            );
          }
          return null;
        }
      } else {
        return null;
      }
    } on DioException catch (e) {
      debugPrint(
        'AssistantService: Error updating assistant: ${e.response?.data ?? e.message}',
      );
      return null;
    } catch (e) {
      debugPrint('AssistantService: Unexpected error: $e');
      return null;
    }
  }
}
