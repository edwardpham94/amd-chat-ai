import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:amd_chat_ai/model/SignUpResponse.dart';
import 'package:dio/dio.dart';

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
      );
      final signUpResponse = SignUpResponse.fromJson(response.data);
      // Save the tokens and user ID to local storage
      await UserStorage.saveUserInfo(signUpResponse);
      return signUpResponse;
    } on DioException catch (e) {
      print('Signup error: ${e.response?.data ?? e.message}');
      return null;
    }
  }
}
