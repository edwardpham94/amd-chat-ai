import 'dart:io';

import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/model/datasource.dart';
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
      final Map<String, dynamic> queryParams = {
        'offset': offset,
        'limit': limit,
      };

      if (q != null) {
        queryParams['q'] = q;
      }

      if (orderField != null) {
        queryParams['order_field'] = orderField;
      }

      if (order != null) {
        queryParams['order'] = order;
      }

      final response = await DioClients.kbClient.get(
        '/kb-core/v1/knowledge',
        queryParameters: queryParams,
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

      final response = await DioClients.kbClient.post(
        '/kb-core/v1/knowledge',
        data: data,
      );

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

  Future<bool> deletDatasource({
    required String knowledgeId,
    required String datasourceId,
  }) async {
    try {
      await DioClients.kbClient.delete(
        '/kb-core/v1/knowledge/$knowledgeId/datasources/$datasourceId',
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error deleting datasource: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  Future<Knowledge> getKnowledgeById(String id) async {
    try {
      final response = await DioClients.kbClient.get(
        '/kb-core/v1/knowledge/$id/units',
      );

      return Knowledge.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error fetching knowledge by ID: ${e.response?.data ?? e.message}',
      );
      rethrow;
    }
  }

  Future<String?> uploadLocalFile({required String filePath}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return null;
      }

      var fileExtension = filePath.split('.').last.toLowerCase();
      var fileupload = await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
        contentType: DioMediaType('application', fileExtension),
      );

      final formData = FormData.fromMap({'files': fileupload});
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/knowledge/files',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      debugPrint(
        'KnowledgeService: Upload file response status: ${response.statusCode}',
      );
      debugPrint('KnowledgeService: Upload file response: ${response.data}');

      return response.data["files"][0]["id"];
    } on DioException catch (e) {
      debugPrint('KnowledgeService: Error uploading file: ${e}');
      debugPrint(
        'KnowledgeService: Error uploading file: ${e.response?.data ?? e.message}',
      );
      return null;
    }
  }

  Future<bool> importDataSourceToKnowledge({
    required String id,
    required String fileName,
    required String fileId,
    required String type,
  }) async {
    try {
      print('KnowledgeService: Importing DataSource to Knowledge with ID: $id');
      print('KnowledgeService: File Name: $fileName $fileId');
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/knowledge/$id/datasources',
        data: {
          'datasources': [
            {
              'name': fileName,
              'type': "local_file",
              'credentials': {'file': fileId},
            },
          ],
        },
      );

      debugPrint(
        'KnowledgeService: Import DataSource To Knowledge response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Import DataSource To Knowledge response: ${response.data}',
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error Import DataSource To Knowledge: ${e}',
      );
      debugPrint(
        'KnowledgeService: Error Import DataSource To Knowledge: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  Future<bool> importConfluenceToKnowledge({
    required String id,
    required String knowledgeName,
    required String url,
    required String username,
    required String apiToken,
  }) async {
    try {
      print('KnowledgeService: Importing Confluence to Knowledge with ID: $id');
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/knowledge/$id/datasources',
        data: {
          'datasources': [
            {
              'name': knowledgeName,
              'type': "confluence",
              'credentials': {
                'url': url,
                'username': username,
                'token': apiToken,
              },
            },
          ],
        },
      );

      debugPrint(
        'KnowledgeService: Import Confluence To Knowledge response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Import Confluence To Knowledge response: ${response.data}',
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error Import DataSource To Knowledge: ${e}',
      );
      debugPrint(
        'KnowledgeService: Error Import DataSource To Knowledge: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  Future<bool> importSlackToKnowledge({
    required String id,
    required String knowledgeName,
    required String apiToken,
  }) async {
    try {
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/knowledge/$id/datasources',
        data: {
          'datasources': [
            {
              'name': knowledgeName,
              'type': "slack",
              'credentials': {'token': apiToken},
            },
          ],
        },
      );

      debugPrint(
        'KnowledgeService: Import Slack To Knowledge response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Import Slack To Knowledge response: ${response.data}',
      );

      return true;
    } on DioException catch (e) {
      debugPrint('KnowledgeService: Error Import Slack To Knowledge: ${e}');
      debugPrint(
        'KnowledgeService: Error Import Slack To Knowledge: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  Future<bool> uploadFromWebsite({
    required String id,
    required String unitName,
    required String webUrl,
  }) async {
    try {
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/knowledge/$id/web',
        data: {'unitName': unitName, 'webUrl': webUrl},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint(
        'KnowledgeService: Upload website response status: ${response.statusCode}',
      );
      debugPrint('KnowledgeService: Upload website response: ${response.data}');

      return true;
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error uploading website: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  Future<Knowledge?> updateKnowledge({
    required String id,
    required String knowledgeName,
    required String description,
  }) async {
    try {
      final response = await DioClients.kbClient.patch(
        '/kb-core/v1/knowledge/$id',
        data: {'knowledgeName': knowledgeName, 'description': description},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint(
        'KnowledgeService: Update Knowledge response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Update Knowledge response: ${response.data}',
      );

      return Knowledge.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error Update Knowledge: ${e.response?.data ?? e.message}',
      );
      return null;
    }
  }

  Future<DatasourceResponse?> getDatasources({
    required String id,
    int offset = 0,
    int limit = 10,
    String? q,
    String? order,
    String? orderField,
    bool? is_favorite,
    bool? is_published,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'offset': offset,
        'limit': limit,
      };

      if (q != null) {
        queryParams['q'] = q;
      }

      if (orderField != null) {
        queryParams['order_field'] = orderField;
      }

      if (order != null) {
        queryParams['order'] = order;
      }

      final response = await DioClients.kbClient.get(
        '/kb-core/v1/knowledge/$id/datasources',
        queryParameters: queryParams,
      );

      return DatasourceResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error fetching datasources: ${e.response?.data ?? e.message}',
      );
      return null;
    }
  }

  Future<bool> handleDisabledDatasource({
    required String knowledgeId,
    required String datasourceId,
    required bool datasourceStatus,
  }) async {
    try {
      final response = await DioClients.kbClient.patch(
        '/kb-core/v1/knowledge/$knowledgeId/datasources/$datasourceId',
        data: {'status': !datasourceStatus},
      );

      debugPrint(
        'KnowledgeService: Disable Datasource response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Disable Datasource response: ${response.data}',
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        'KnowledgeService: Error Disable datasource: ${e.response?.data ?? e.message}',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> publishTelegramBot({
    required String assistantId,
    required String botToken,
  }) async {
    try {
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/bot-integration/telegram/publish/$assistantId',
        data: {'botToken': botToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint(
        'KnowledgeService: Publish Telegram bot response: ${response}',
      );

      debugPrint(
        'KnowledgeService: Publish Telegram bot response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Publish Telegram bot response: ${response.data}',
      );

      // Return success status and redirect URL
      return {
        'success': true,
        'redirect': response.data['redirect'] as String? ?? '',
      };
    } on DioException catch (e) {
      debugPrint('KnowledgeService: Error publishing Telegram bot: ${e}');
      debugPrint(
        'KnowledgeService: Error publishing Telegram bot: ${e.response?.data ?? e.message}',
      );
      return {'success': false, 'redirect': ''};
    }
  }

  Future<Map<String, dynamic>> publishMessengerBot({
    required String assistantId,
    required String botToken,
    required String pageId,
    required String appSecret,
  }) async {
    try {
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/bot-integration/messenger/publish/$assistantId',
        data: {'botToken': botToken, 'pageId': pageId, 'appSecret': appSecret},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint(
        'KnowledgeService: Publish Messenger bot response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Publish Messenger bot response: ${response.data}',
      );

      // Return success status and redirect URL if available
      return {
        'success': true,
        'redirect': response.data['redirect'] as String? ?? '',
      };
    } on DioException catch (e) {
      debugPrint('KnowledgeService: Error publishing Messenger bot: ${e}');
      debugPrint(
        'KnowledgeService: Error publishing Messenger bot: ${e.response?.data ?? e.message}',
      );
      return {'success': false, 'redirect': ''};
    }
  }

  Future<Map<String, dynamic>> publishSlackBot({
    required String assistantId,
    required String botToken,
    required String clientId,
    required String clientSecret,
    required String signingSecret,
  }) async {
    try {
      final response = await DioClients.kbClient.post(
        '/kb-core/v1/bot-integration/slack/publish/$assistantId',
        data: {
          'botToken': botToken,
          'clientId': clientId,
          'clientSecret': clientSecret,
          'signingSecret': signingSecret,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint(
        'KnowledgeService: Publish Slack bot response status: ${response.statusCode}',
      );
      debugPrint(
        'KnowledgeService: Publish Slack bot response: ${response.data}',
      );

      // Return success status and redirect URL if available
      return {
        'success': true,
        'redirect': response.data['redirect'] as String? ?? '',
      };
    } on DioException catch (e) {
      debugPrint('KnowledgeService: Error publishing Slack bot: ${e}');
      debugPrint(
        'KnowledgeService: Error publishing Slack bot: ${e.response?.data ?? e.message}',
      );
      return {'success': false, 'redirect': ''};
    }
  }
}
