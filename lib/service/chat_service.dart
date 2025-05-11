import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/model/email_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  Future<Response?> suggestReplyIdeas({
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

      debugPrint('Sending message with data: $requestData');

      final response = await DioClients.jarvisClient.post(
        '/api/v1/ai-email/reply-ideas',
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
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

  // Send message with streaming response
  Stream<Map<String, dynamic>> sendMessageStream({
    required String content,
    String? conversationId,
    required String kbAssistantId,
  }) async* {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      // Construct request payload
      final Map<String, dynamic> payload = {'message': content};

      // Add conversation ID if it exists
      if (conversationId != null) {
        payload['conversationId'] = conversationId;
      }

      // Make the request with responseType set to stream
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/ai-assistant/$kbAssistantId/ask',
        data: payload,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
            'Connection': 'keep-alive',
            'Content-Type': 'application/json',
            if (userId != null) 'x-jarvis-guid': userId,
          },
        ),
      );

      // Process the stream data
      String accumulatedContent = '';

      await for (final chunk in response.data.stream) {
        final String chunkString = String.fromCharCodes(chunk);
        final List<String> events =
            chunkString.split('\n\n').where((e) => e.isNotEmpty).toList();

        for (final event in events) {
          if (event.isEmpty) continue;

          try {
            // Parse event name and data
            final eventLines = event.split('\n');
            String? eventName;
            String? eventData;

            for (final line in eventLines) {
              if (line.startsWith('event:')) {
                eventName = line.substring(6).trim();
              } else if (line.startsWith('data:')) {
                eventData = line.substring(5).trim();
              }
            }

            if (eventName != null && eventData != null) {
              // Parse the JSON data
              final Map<String, dynamic> data = {};

              try {
                // Parse the JSON data
                final jsonData = jsonDecode(eventData);

                if (jsonData is Map<String, dynamic>) {
                  data.addAll(jsonData);

                  // Save the conversation ID if present
                  if (data['conversationId'] != null) {
                    data['conversationId'] = data['conversationId'].toString();
                  }
                }

                // Handle different event types
                if (eventName == 'message') {
                  // Accumulate content
                  accumulatedContent += data['content'] ?? '';

                  // Return chunk with type and accumulated content
                  yield {
                    'type': 'chunk',
                    'content': data['content'] ?? '',
                    'accumulatedContent': accumulatedContent,
                    'conversationId': data['conversationId'],
                  };
                } else if (eventName == 'message_end') {
                  // Return complete message
                  yield {
                    'type': 'complete',
                    'content': accumulatedContent,
                    'conversationId': data['conversationId'],
                  };
                }
              } catch (e) {
                debugPrint('Error parsing JSON data: $e');
                yield {'type': 'error', 'error': 'Error parsing response data'};
              }
            }
          } catch (e) {
            debugPrint('Error processing event: $e');
            yield {'type': 'error', 'error': 'Error processing event'};
          }
        }
      }
    } catch (e) {
      debugPrint('Stream error: $e');
      yield {'type': 'error', 'error': e.toString()};
    }
  }

  // Non-streaming message sending (fallback)
  Future<Map<String, dynamic>> sendMessageNonStreaming({
    required String content,
    String? conversationId,
    required String kbAssistantId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getString('user_id');

      // Construct request payload
      final Map<String, dynamic> payload = {'message': content};

      // Add conversation ID if it exists
      if (conversationId != null) {
        payload['conversationId'] = conversationId;
      }

      // Make the request with standard response
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/ai-assistant/$kbAssistantId/ask',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            if (userId != null) 'x-jarvis-guid': userId,
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'type': 'success',
          'content': response.data['answer'] ?? '',
          'conversationId': response.data['conversationId'],
        };
      } else {
        return {
          'type': 'error',
          'error': 'Request failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Non-streaming error: $e');
      return {'type': 'error', 'error': e.toString()};
    }
  }

  Stream<Map<String, dynamic>> sendEmailMessage({
    required EmailRequest emailRequest,
    String? conversationId,
  }) async* {
    try {
      // Prepare the request data
      final Map<String, dynamic> requestData = {
        'email': emailRequest.email,
        'action': emailRequest.action,
        'mainIdea': emailRequest.mainIdea,
        'metadata': {
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

      debugPrint('Sending email request with data: $requestData');

      final response = await DioClients.jarvisClient.post(
        '/api/v1/ai-email',
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Connection': 'keep-alive',
            'Content-Type': 'application/json',
          },
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';
      String accumulatedContent = '';

      await for (final chunk in stream) {
        // Convert chunk to string and add to buffer
        buffer += String.fromCharCodes(chunk);

        // Process complete events in buffer
        while (buffer.contains('\n\n')) {
          final eventEndIndex = buffer.indexOf('\n\n');
          final event = buffer.substring(0, eventEndIndex);
          buffer = buffer.substring(eventEndIndex + 2);

          // Parse event
          final eventLines = event.split('\n');
          String? eventName;
          String? eventData;

          for (final line in eventLines) {
            if (line.startsWith('event: ')) {
              eventName = line.substring(7);
            } else if (line.startsWith('data: ')) {
              eventData = line.substring(6);
            }
          }

          if (eventData != null) {
            try {
              final data = jsonDecode(eventData);
              if (data is Map<String, dynamic>) {
                if (data['type'] == 'error') {
                  yield {
                    'type': 'error',
                    'error': data['error'] ?? 'Unknown error',
                  };
                  return;
                }

                final content = data['content'] as String?;
                if (content != null) {
                  accumulatedContent += content;
                  yield {
                    'type': 'chunk',
                    'content': content,
                    'conversationId': data['conversationId'],
                  };
                }

                if (eventName == 'complete') {
                  yield {
                    'type': 'complete',
                    'content': accumulatedContent,
                    'conversationId': data['conversationId'],
                  };
                }
              }
            } catch (e) {
              debugPrint('Error parsing event data: $e');
              yield {'type': 'error', 'error': 'Error parsing response data'};
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Email stream error: $e');
      yield {'type': 'error', 'error': e.toString()};
    }
  }
}
