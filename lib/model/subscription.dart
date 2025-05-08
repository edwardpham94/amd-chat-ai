import 'dart:convert';

class Subscription {
  final String name;
  final int dailyTokens;
  final int monthlyTokens;
  final int annuallyTokens;

  Subscription({
    required this.name,
    required this.dailyTokens,
    required this.monthlyTokens,
    required this.annuallyTokens,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      name: json['name'] ?? '',
      dailyTokens: json['dailyTokens'] ?? 0,
      monthlyTokens: json['monthlyTokens'] ?? 0,
      annuallyTokens: json['annuallyTokens'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dailyTokens': dailyTokens,
      'monthlyTokens': monthlyTokens,
      'annuallyTokens': annuallyTokens,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
