class Knowledge {
  final String? createdAt;
  final String? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? userId;
  final String? id;
  final String knowledgeName;
  final String description;

  Knowledge({
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.userId,
    this.id,
    required this.knowledgeName,
    required this.description,
  });

  factory Knowledge.fromJson(Map<String, dynamic> json) {
    return Knowledge(
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      userId: json['userId'] as String?,
      id: json['id'] as String?,
      knowledgeName: json['knowledgeName'] ?? 'Unknown Name',
      description: json['description'] ?? 'No description available',
    );
  }
}

class KnowledgeResponse {
  final List<Knowledge> data;
  final Meta meta;

  KnowledgeResponse({required this.data, required this.meta});

  factory KnowledgeResponse.fromJson(Map<String, dynamic> json) {
    return KnowledgeResponse(
      data:
          (json['data'] as List<dynamic>)
              .map((item) => Knowledge.fromJson(item as Map<String, dynamic>))
              .toList(),
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class Meta {
  final int limit;
  final int offset;
  final int total;
  final bool hasNext;

  Meta({
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasNext,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      limit: json['limit'] ?? 0,
      offset: json['offset'] ?? 0,
      total: json['total'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }
}
