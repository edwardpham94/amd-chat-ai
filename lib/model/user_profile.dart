class UserProfile {
  final String id;
  final String email;
  final String username;
  final List<String> roles;
  final Map<String, dynamic> geo;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.roles,
    required this.geo,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      geo: json['geo'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'roles': roles,
      'geo': geo,
    };
  }
}
