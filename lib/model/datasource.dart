class Datasource {
  final String? createdAt;
  final String? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? id;
  final String name;
  final bool status;
  final String? userId;
  final String? knowledgeId;
  final Metadata metadata;

  Datasource({
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.userId,
    this.id,
    required this.name,
    required this.knowledgeId,
    this.status = false,
    required this.metadata,
  });

  factory Datasource.fromJson(Map<String, dynamic> json) {
    return Datasource(
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      userId: json['userId'] as String?,
      id: json['id'] as String?,
      name: json['name'] ?? 'Unknown Name',
      knowledgeId: json['knowledgeId'] ?? 'Unknown Knowledge ID',
      status: json['status'] ?? false,
      metadata: Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }
}

class DatasourceResponse {
  final List<Datasource> data;
  final Meta meta;

  DatasourceResponse({required this.data, required this.meta});

  factory DatasourceResponse.fromJson(Map<String, dynamic> json) {
    return DatasourceResponse(
      data:
          (json['data'] as List<dynamic>)
              .map((item) => Datasource.fromJson(item as Map<String, dynamic>))
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

class Metadata {
  final String? fileId;
  final String? fileUrl;
  final String? mimeType;
  final String? knowledgeId;

  Metadata({this.fileId, this.fileUrl, this.mimeType, this.knowledgeId});

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      fileId: json['fileId'] as String?,
      fileUrl: json['fileUrl'] as String?,
      mimeType: json['mimeType'] as String?,
      knowledgeId: json['knowledgeId'] as String?,
    );
  }
}
