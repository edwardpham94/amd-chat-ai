import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/sign_up_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  Future<SignUpResponse?> signUp(String email, String password) async {
    try {
      final response = await DioClients.authClient.post(
        '/api/v1/auth/password/sign-up',
        data: {
          'email': email,
          'password': password,
          'verification_callback_url':
              'https://auth.dev.jarvis.cx/handler/email-verification?after_auth_return_to=%2Fauth%2Fsignin%3Fclient_id%3Djarvis_chat%26redirect%3Dhttps%253A%252F%252Fchat.dev.jarvis.cx%252Fauth%252Foauth%252Fsuccess',
        },
        // options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final signUpResponse = SignUpResponse.fromJson(response.data);
      // Save the tokens and user ID to local storage
      await UserStorage.saveUserInfo(signUpResponse);
      return signUpResponse;
    } on DioException catch (e) {
      debugPrint('Signup error: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  Future<SignUpResponse?> login(String email, String password) async {
    try {
      final response = await DioClients.authClient.post(
        '/api/v1/auth/password/sign-in',
        data: {'email': email, 'password': password},
        // options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final signInResponse = SignUpResponse.fromJson(response.data);
      await UserStorage.saveUserInfo(signInResponse);
      return signInResponse;
    } on DioException catch (e) {
      debugPrint('Signin error: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  Future<SignUpResponse?> getNewAccessToken() async {
    try {
      var refreshToken = await UserStorage.getRefreshToken();

      final response = await DioClients.authClient.post(
        '/api/v1/auth/sessions/current/refresh',
        options: Options(headers: {'X-Stack-Refresh-Token': refreshToken}),
      );
      final signInResponse = SignUpResponse.fromJson(response.data);
      await UserStorage.saveUserInfo(signInResponse);
      return signInResponse;
    } on DioException catch (e) {
      debugPrint('RefreshToken error: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      var accessToken = await UserStorage.getAccessToken();
      var refreshToken = await UserStorage.getRefreshToken();

      if (accessToken == null) {
        debugPrint('Access token is null');
        return false;
      }

      await DioClients.authClient.delete(
        '/api/v1/auth/sessions/current',
        data: {},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'X-Stack-Refresh-Token': refreshToken,
          },
        ),
      );

      await UserStorage.deleteTokens();
      return true;
    } on DioException catch (e) {
      debugPrint('Logout error: ${e.response?.data ?? e.message}');
      return false;
    }
  }
}
