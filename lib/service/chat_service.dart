import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:dio/dio.dart';
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

      final response = await DioClients.jarvisClient.get(
        '/api/v1/ai-chat/conversations',
        queryParameters: {
          'cursor': cursor,
          'limit': limit,
          'assistantId': assistantId,
          'assistantModel': 'dify',
        },
      );

      return response;
    } on DioException catch (e) {
      print('Fetch conversations error: ${e.response?.data ?? e.message}');
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

      final response = await DioClients.jarvisClient.get(
        '/api/v1/ai-chat/conversations/$conversationId/messages',
        queryParameters: {
          'cursor': cursor,
          'limit': limit,
          'assistantId': assistantId,
          'assistantModel': 'dify', // Required
        },
      );

      return response;
    } on DioException catch (e) {
      print('Fetch messages error: ${e.response?.data ?? e.message}');
      return null;
    }
  }


  Future<Response?> sendMessage({
    required String content,
    required String conversationId,
    required String assistantId, // e.g., 'gpt-4o-mini'
    String? jarvisGuid,
    List<String> files = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await DioClients.jarvisClient.post(
        '/api/v1/ai-chat/messages',
        data: {
          'content': content,
          'files': files,
          'metadata': metadata ?? {},
          'assistant': {
            'id': assistantId,
            'model': 'dify', 
          },
          'conversation': {'id': conversationId},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            if (jarvisGuid != null) 'x-jarvis-guid': jarvisGuid,
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      print('Send message error: ${e.response?.data ?? e.message}');
      return null;
    }
  }

}
