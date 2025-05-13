class EmailRequest {
  String? mainIdea;
  String? email;
  String? action;
  EmailMetadata? metadata;

  EmailRequest({this.mainIdea, this.email, this.action, this.metadata});

  EmailRequest.fromJson(Map<String, dynamic> json) {
    mainIdea = json['mainIdea'];
    email = json['email'];
    action = json['action'];
    metadata =
        json['metadata'] != null
            ? EmailMetadata.fromJson(json['metadata'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mainIdea'] = mainIdea;
    data['email'] = email;
    data['action'] = action;
    if (metadata != null) {
      data['metadata'] = metadata!.toJson();
    }
    return data;
  }
}

class EmailMetadata {
  String? subject;
  String? sender;
  String? receiver;
  String? language;
  String? style;

  EmailMetadata({
    this.subject,
    this.sender,
    this.receiver,
    this.language,
    this.style,
  });

  EmailMetadata.fromJson(Map<String, dynamic> json) {
    subject = json['subject'];
    sender = json['sender'];
    receiver = json['receiver'];
    language = json['language'];
    style = json['style'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['subject'] = subject;
    data['sender'] = sender;
    data['receiver'] = receiver;
    data['language'] = language;
    data['style'] = style;
    return data;
  }
}
