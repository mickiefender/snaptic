class EventInteraction {
  final String id;
  final String userId;
  final String eventId;
  final String type; // 'like', 'share', 'view', 'comment'
  final String? content; // For comments
  final DateTime createdAt;

  EventInteraction({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.type,
    this.content,
    required this.createdAt,
  });

  factory EventInteraction.fromJson(Map<String, dynamic> json) {
    return EventInteraction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      type: json['type'] as String,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'user_id': userId,
      'event_id': eventId,
      'type': type,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
    
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}