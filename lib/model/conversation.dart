class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ConversationResponse {
  final bool hasMore;
  final List<Conversation> items;

  ConversationResponse({
    required this.hasMore,
    required this.items,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) {
    return ConversationResponse(
      hasMore: json['has_more'] as bool,
      items: (json['items'] as List)
          .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
