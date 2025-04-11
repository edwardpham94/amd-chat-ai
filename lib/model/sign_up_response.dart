class SignUpResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;

  SignUpResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  // Factory constructor to create an instance from JSON
  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      userId: json['user_id'],
    );
  }

  // Method to convert the instance back to JSON
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_id': userId,
    };
  }
}
