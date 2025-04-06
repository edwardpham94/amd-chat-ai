import 'package:shared_preferences/shared_preferences.dart';
import 'package:amd_chat_ai/model/SignUpResponse.dart';

class UserStorage {
  static Future<void> saveUserInfo(SignUpResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', response.accessToken);
    await prefs.setString('refresh_token', response.refreshToken);
    await prefs.setString('user_id', response.userId);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}
