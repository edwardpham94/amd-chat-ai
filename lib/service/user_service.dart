import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/subscription.dart';
import 'package:amd_chat_ai/model/user_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class UserService {
  Future<UserProfile?> getUserProfile() async {
    try {
      final accessToken = await UserStorage.getAccessToken();

      debugPrint('UserService: Fetching user profile');

      final response = await DioClients.jarvisClient.get(
        '/api/v1/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'x-jarvis-guid': '',
          },
        ),
      );

      debugPrint('UserService: User profile fetched successfully');

      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        'UserService: Error fetching user profile: ${e.response?.data ?? e.message}',
      );
      return null;
    }
  }

  Future<Subscription?> getSubscriptionInfo() async {
    try {
      final accessToken = await UserStorage.getAccessToken();

      debugPrint('UserService: Fetching subscription info');

      final response = await DioClients.jarvisClient.get(
        '/api/v1/subscriptions/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'x-jarvis-guid': '',
          },
        ),
      );

      debugPrint('UserService: Subscription info fetched successfully');

      return Subscription.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
        'UserService: Error fetching subscription info: ${e.response?.data ?? e.message}',
      );
      return null;
    }
  }
}
