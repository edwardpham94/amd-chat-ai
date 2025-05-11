import 'dart:io';

import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
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
      // debugPrint("KnowledgeService: Starting getKnowledge call");
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
      // debugPrint("KnowledgeService: User ID: $userId");
      // debugPrint("KnowledgeService: Access Token: $accessToken");

      final response = await DioClients.kbClient.get(
        '/kb-core/v1/knowledge',
        queryParameters: queryParams,
      );

      // print(
      //   '>>>>>>>>>>>>>>>>>>>>>>>>> KnowledgeService-GET-getknowledges: Response data: ${response.data} $queryParams',
      // );

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

      // debugPrint('KnowledgeService: Create request data: $data');

      final response = await DioClients.kbClient.post(
        '/kb-core/v1/knowledge',
        data: data,
      );

      // debugPrint(
      //   'KnowledgeService: Create knowledge response status: ${response.statusCode}',
      // );
      // debugPrint(
      //   'KnowledgeService: Create knowledge response: ${response.data}',
      // );

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

  // Future<FormData> createFormData(String fileName, String filePath) async {
  //   String fileExtension = fileName.split('.').last.toLowerCase();

  //   FileExtensionType fileType;
  // }

  Future<String?> uploadLocalFile({required String filePath}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        print('KnowledgeService: File does not exist at path: $filePath');
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

      print(
        'KnowledgeService: Uploaded file ID: ${response.data["files"][0]["id"]}',
      );

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
      print('KnowledgeService: Importing Slack to Knowledge with ID: $id');
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

      print('KnowledgeService: Datasource queryParams: $queryParams');

      // print('KnowledgeService: Datasource queryParams with knowledgeID: $id');

      final response = await DioClients.kbClient.get(
        '/kb-core/v1/knowledge/$id/datasources',
        queryParameters: queryParams,
      );

      // print('KnowledgeService: Datasource response data: ${response.data}');

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
}
