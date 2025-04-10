class Prompt {
  final String id;
  final String title;
  final String content;
  final String description;
  final String category;
  final String language;
  final bool isPublic;
  final bool isFavorite;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Prompt({
    required this.id,
    required this.title,
    required this.content,
    required this.description,
    required this.category,
    required this.language,
    required this.isPublic,
    required this.isFavorite,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      language: json['language'] ?? 'English',
      isPublic: json['isPublic'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'description': description,
      'category': category,
      'language': language,
      'isPublic': isPublic,
      'isFavorite': isFavorite,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PromptResponse {
  final bool hasNext;
  final int offset;
  final int limit;
  final int total;
  final List<Prompt> items;

  PromptResponse({
    required this.hasNext,
    required this.offset,
    required this.limit,
    required this.total,
    required this.items,
  });

  factory PromptResponse.fromJson(Map<String, dynamic> json) {
    return PromptResponse(
      hasNext: json['hasNext'] ?? false,
      offset: json['offset'] ?? 0,
      limit: json['limit'] ?? 0,
      total: json['total'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => Prompt.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
