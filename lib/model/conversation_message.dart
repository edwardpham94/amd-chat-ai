import 'package:amd_chat_ai/presentation/screens/widgets/chat_message.dart';

class ConversationMessage {
  final String query;
  final String answer;
  final DateTime createdAt;
  final Map<String, dynamic> inputs;
  final MessageType userType = MessageType.user;
  final MessageType assistantType = MessageType.assistant;

  ConversationMessage({
    required this.query,
    required this.answer,
    required this.createdAt,
    required this.inputs,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      query: json['query'] as String,
      answer: json['answer'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      inputs: json['inputs'] as Map<String, dynamic>,
    );
  }
}

class ConversationMessagesResponse {
  final bool hasMore;
  final List<ConversationMessage> items;

  ConversationMessagesResponse({required this.hasMore, required this.items});

  factory ConversationMessagesResponse.fromJson(Map<String, dynamic> json) {
    return ConversationMessagesResponse(
      hasMore: json['has_more'] as bool,
      items:
          (json['items'] as List)
              .map(
                (item) =>
                    ConversationMessage.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}
