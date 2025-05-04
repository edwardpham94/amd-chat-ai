import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/knowledge.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class KnowledgeService {
  Future<KnowledgeResponse?> getKnowledges({
    int offset = 0,
    int limit = 10,
    String? q,
    String? order,
    String? orderField,
  }) async {
    try {
      debugPrint("KnowledgeService: Starting getKnowledge call");
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'offset': offset,
        'limit': limit,
      };

      // Add optional filters if provided
      if (q != null) {
        queryParams['q'] = q;
      }

      if (orderField != null) {
        queryParams['order_field'] = orderField;
      }

      if (order != null) {
        queryParams['order'] = order;
      }

      // Get user ID for the header
      final userId = await UserStorage.getUserId();
      final accessToken = await UserStorage.getAccessToken();
      debugPrint("KnowledgeService: User ID: $userId");
      debugPrint("KnowledgeService: Access Token: $accessToken");

      final response = await DioClients.kbClient.get(
        '/kb-core/v1/knowledge',
        queryParameters: queryParams,
      );

      print(
        '>>>>>>>>>>>>>>>>>>>>>>>>> KnowledgeService-GET-getknowledges: Response data: ${response.data} $queryParams',
      );

      return KnowledgeResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error fetching Knowledge: ${e.response?.data ?? e.message}',
      );
      return null;
    }
  }

  Future<Knowledge?> createKnowledge({
    required String knowledgeName,
    required String description,
  }) async {
    try {
      debugPrint('KnowledgeService: Creating new knowledge');
      final Map<String, dynamic> data = {
        'knowledgeName': knowledgeName,
        'description': description,
      };

      debugPrint('KnowledgeService: Create request data: $data');

      final response = await DioClients.kbClient.post(
        '/kb-core/v1/knowledge',
        data: data,
      );

      debugPrint(
        'KnowledgeService: Create knowledge response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Create knowledge response: ${response.data}',
      );

      // Parse the response into a Knowledge object
      return Knowledge.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error creating knowledge: ${e.response?.data ?? e.message}',
      );
      return null;
    }
  }

  Future<bool> deleteKnowledge(String id) async {
    try {
      await DioClients.kbClient.delete('/kb-core/v1/knowledge/$id');

      return true;
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error deleting knowledge: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  Future<Knowledge> getKnowledgeById(String id) async {
    try {
      final response = await DioClients.kbClient.get(
        '/kb-core/v1/knowledge/$id/units',
      );

      print(
        'KnowledgeService: Response data for knowledge by ID: ${response.data}',
      );

      return Knowledge.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error fetching knowledge by ID: ${e.response?.data ?? e.message}',
      );
      rethrow;
    }
  }
}
