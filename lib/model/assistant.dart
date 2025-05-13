class Assistant {
  final String id;
  final String assistantName;
  final String description;
  final String instructions;
  final String userId;
  final bool isDefault;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> permissions;
  bool? isSelected;
  String model = 'knowledge-base'; // Default model for all assistants

  Assistant({
    required this.id,
    required this.assistantName,
    required this.description,
    required this.instructions,
    required this.userId,
    required this.isDefault,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    required this.permissions,
    this.isSelected,
    this.model = 'knowledge-base', // Default model for assistants
  });

  factory Assistant.fromJson(Map<String, dynamic> json) {
    return Assistant(
      id: json['id'] as String,
      assistantName: json['assistantName'] as String,
      description: json['description'] as String,
      instructions: json['instructions'] as String,
      userId: json['userId'] as String,
      isDefault: json['isDefault'] as bool,
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      permissions:
          json['permissions'] != null
              ? (json['permissions'] as List<dynamic>)
                  .map((e) => e as String)
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assistantName': assistantName,
      'description': description,
      'instructions': instructions,
      'userId': userId,
      'isDefault': isDefault,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'permissions': permissions,
    };
  }
}

class AssistantResponse {
  final List<Assistant> items;
  final int total;
  final int offset;
  final int limit;
  final bool hasNext;

  AssistantResponse({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasNext,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      items:
          (json['data'] as List<dynamic>)
              .map((e) => Assistant.fromJson(e as Map<String, dynamic>))
              .toList(),
      total: json['meta']['total'] as int,
      offset: json['meta']['offset'] as int,
      limit: json['meta']['limit'] as int,
      hasNext: json['meta']['hasNext'] as bool,
    );
  }
}
