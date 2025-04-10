// dio_clients.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'user_storage.dart';

class DioClients {
  // Lock to prevent multiple token refresh requests
  static bool _isRefreshing = false;

  // Method to refresh the token
  static Future<bool> refreshToken() async {
    if (_isRefreshing) return false;

    try {
      _isRefreshing = true;
      debugPrint('Refreshing token...');

      final refreshToken = await UserStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('No refresh token found');
        _isRefreshing = false;
        return false;
      }

      debugPrint('Refresh token: $refreshToken');

      final response = await authClient.post(
        '/api/v1/auth/sessions/current/refresh',
        options: Options(headers: {'X-Stack-Refresh-Token': refreshToken}),
      );

      debugPrint('Refresh response: ${response}');

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        final newToken = response.data['access_token'];
        await UserStorage.updateAccessToken(newToken);
        debugPrint('Token refreshed successfully');
        _isRefreshing = false;
        return true;
      } else {
        debugPrint('Failed to refresh token: ${response.statusCode}');
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      _isRefreshing = false;
      return false;
    }
  }

  static final Dio authClient = Dio(
      BaseOptions(
        baseUrl: ApiConfig.authBaseUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-Stack-Access-Type': 'client',
          'X-Stack-Project-Id': 'a914f06b-5e46-4966-8693-80e4b9f4f409',
          'X-Stack-Publishable-Client-Key':
              'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr',
        },
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await UserStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('Auth client received 401, refreshing token...');
            // Try to refresh the token
            final refreshed = await refreshToken();
            if (refreshed) {
              // Retry the request with the new token
              final token = await UserStorage.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';

              // Create a new request with the updated token
              final opts = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );

              final response = await authClient.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );

              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );

  static final Dio jarvisClient = Dio(
      BaseOptions(
        baseUrl: ApiConfig.jarvisBaseUrl,
        headers: {'Content-Type': 'application/json'},
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await UserStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('Jarvis client received 401, refreshing token...');
            // Try to refresh the token
            final refreshed = await refreshToken();
            if (refreshed) {
              // Retry the request with the new token
              final token = await UserStorage.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';

              // Create a new request with the updated token
              final opts = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );

              final response = await jarvisClient.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );

              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );

  static final Dio kbClient = Dio(
      BaseOptions(
        baseUrl: ApiConfig.kbBaseUrl,
        headers: {'Content-Type': 'application/json'},
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await UserStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('KB client received 401, refreshing token...');
            // Try to refresh the token
            final refreshed = await refreshToken();
            if (refreshed) {
              // Retry the request with the new token
              final token = await UserStorage.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';

              // Create a new request with the updated token
              final opts = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );

              final response = await kbClient.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );

              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
}
