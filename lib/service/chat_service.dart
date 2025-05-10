import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/model/email_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatAIService {
  Future<Response?> fetchConversations({
    String? cursor,
    int limit = 100,
    String? assistantId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      // Determine model type if assistantId is provided
      String assistantModel = 'dify'; // Default to dify
      if (assistantId != null) {
        // Predefined models start with gpt-, claude-, or gemini-
        final bool isCustomAssistant =
            !assistantId.startsWith('gpt-') &&
            !assistantId.startsWith('claude-') &&
            !assistantId.startsWith('gemini-');
        assistantModel = isCustomAssistant ? 'knowledge-base' : 'dify';
      }

      debugPrint('Fetching conversations for user: $userId');

      final response = await DioClients.jarvisClient.get(
        '/api/v1/ai-chat/conversations',
        queryParameters: {
          'assistantModel': assistantModel,
          if (assistantId != null) 'assistantId': assistantId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            if (userId != null) 'x-jarvis-guid': userId,
          },
        ),
      );

      debugPrint(
        'Fetched ${(response.data['items'] as List?)?.length ?? 0} conversations',
      );
      return response;
    } on DioException catch (e) {
      debugPrint('Fetch conversations error: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  Future<Response?> fetchConversationHistory({
    required String conversationId,
    String? cursor,
    int limit = 100,
    String? assistantId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      // Determine model type if assistantId is provided
      String assistantModel = 'dify';
      if (assistantId != null) {
        // Predefined models start with gpt-, claude-, or gemini-
        final bool isCustomAssistant =
            !assistantId.startsWith('gpt-') &&
            !assistantId.startsWith('claude-') &&
            !assistantId.startsWith('gemini-');
        assistantModel = isCustomAssistant ? 'knowledge-base' : 'dify';
      }

      debugPrint('Fetching messages for conversation: $conversationId');

      final response = await DioClients.jarvisClient.get(
        '/api/v1/ai-chat/conversations/$conversationId/messages/',
        queryParameters: {
          'assistantModel': assistantModel,
          if (assistantId != null) 'assistantId': assistantId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            if (userId != null) 'x-jarvis-guid': userId,
          },
        ),
      );

      debugPrint(
        'Fetched ${(response.data['items'] as List?)?.length ?? 0} messages',
      );
      return response;
    } on DioException catch (e) {
      debugPrint('Fetch messages error: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  Future<Response?> sendMessage({
    required String content,
    required String assistantId, // e.g., 'gpt-4o-mini'
    String? conversationId,
    String? jarvisGuid,
    List<String> files = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      // Determine whether this is a predefined model or custom assistant
      // Predefined models contain a hyphen, custom assistant IDs are typically UUIDs without hyphens
      final bool isCustomAssistant =
          !assistantId.startsWith('gpt-') &&
          !assistantId.startsWith('claude-') &&
          !assistantId.startsWith('gemini-');
      final String modelType = isCustomAssistant ? 'knowledge-base' : 'dify';

      // Prepare the request data
      final Map<String, dynamic> requestData = {
        'content': content,
        'files': files,
        'assistant': {
          'id': assistantId,
          'model': modelType,
          'name': _getAssistantName(assistantId),
        },
      };

      // Handle metadata and conversation ID
      if (conversationId != null) {
        // If we have a conversation ID, include it in the metadata
        requestData['metadata'] = {
          'conversation': {'id': conversationId, 'messages': []},
        };
      } else {
        // For new conversations, just include empty messages array
        requestData['metadata'] = {
          'conversation': {'messages': []},
        };
      }

      // If additional metadata was provided, merge it
      if (metadata != null) {
        // Merge with existing metadata
        final existingMetadata =
            requestData['metadata'] as Map<String, dynamic>;
        requestData['metadata'] = {...existingMetadata, ...metadata};
      }

      debugPrint('Sending message with data: $requestData');

      final response = await DioClients.jarvisClient.post(
        '/api/v1/ai-chat/messages',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'x-jarvis-guid': jarvisGuid ?? userId ?? '',
          },
        ),
      );

      debugPrint('Message sent successfully: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Response data: ${response.data}');
        // If this was a new conversation, save the conversation ID
        if (conversationId == null && response.data['conversationId'] != null) {
          debugPrint(
            'New conversation created with ID: ${response.data['conversationId']}',
          );
        }
      }

      return response;
    } on DioException catch (e) {
      debugPrint('Send message error: ${e.response?.data ?? e.message}');
      return null;
    }
  }


  Future<Response?> sendResponseMail({
    required EmailRequest emailRequest,
    required String assistantId, // e.g., 'gpt-4o-mini'
    String? conversationId,
    String? jarvisGuid,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      // Determine whether this is a predefined model or custom assistant
      // Predefined models contain a hyphen, custom assistant IDs are typically UUIDs without hyphens
      final bool isCustomAssistant =
          !assistantId.startsWith('gpt-') &&
          !assistantId.startsWith('claude-') &&
          !assistantId.startsWith('gemini-');
      final String modelType = isCustomAssistant ? 'knowledge-base' : 'dify';

      // Prepare the request data
      final Map<String, dynamic> requestData = {
        // 'assistant': {
        //   'id': assistantId,
        //   'model': modelType,
        //   'name': _getAssistantName(assistantId),
        // },
        'email': emailRequest.email,
        'action': emailRequest.action,
        'mainIdea': emailRequest.mainIdea,
        'metadata': {
          "context": [],
          'subject': emailRequest.metadata?.subject,
          'sender': emailRequest.metadata?.sender,
          'receiver': emailRequest.metadata?.receiver,
          'language': emailRequest.metadata?.language,
          'style': {
            "length": "long",
            "formality": "neutral",
            "tone": "friendly",
          },
        },
      };

      // // Handle metadata and conversation ID
      // if (conversationId != null) {
      //   // If we have a conversation ID, include it in the metadata
      //   requestData['metadata'] = {
      //     'conversation': {'id': conversationId, 'messages': []},
      //   };
      // } else {
      //   // For new conversations, just include empty messages array
      //   requestData['metadata'] = {
      //     'conversation': {'messages': []},
      //   };
      // }

      // // If additional metadata was provided, merge it
      // if (metadata != null) {
      //   // Merge with existing metadata
      //   final existingMetadata =
      //       requestData['metadata'] as Map<String, dynamic>;
      //   requestData['metadata'] = {...existingMetadata, ...metadata};
      // }

      debugPrint('Sending message with data: $requestData');

      final response = await DioClients.jarvisClient.post(
        '/api/v1/ai-email',
        data: requestData,
        options: Options(
          headers: {
            // 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('Message sent successfully: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Response data: ${response.data}');
        // If this was a new conversation, save the conversation ID
        if (conversationId == null && response.data['conversationId'] != null) {
          debugPrint(
            'New conversation created with ID: ${response.data['conversationId']}',
          );
        }
      }

      return response;
    } on DioException catch (e) {
      debugPrint('Send message error: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  // Helper method to get assistant name from ID
  String _getAssistantName(String assistantId) {
    switch (assistantId) {
      case 'gpt-4o':
        return 'GPT-4o';
      case 'gpt-4o-mini':
        return 'GPT-4o mini';
      case 'claude-3-haiku-20240307':
        return 'Claude 3 Haiku';
      case 'claude-3-5-sonnet-20240620':
        return 'Claude 3.5 Sonnet';
      case 'gemini-1.5-flash-latest':
        return 'Gemini 1.5 Flash';
      case 'gemini-1.5-pro-latest':
        return 'Gemini 1.5 Pro';
      default:
        return assistantId;
    }
  }
}
