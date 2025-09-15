class Story {
  final String id;
  final String organizerId;
  final String eventId;
  final String imageUrl;
  final String? videoUrl;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final bool isActive;

  Story({
    required this.id,
    required this.organizerId,
    required this.eventId,
    required this.imageUrl,
    this.videoUrl,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.isActive = true,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      organizerId: json['organizer_id'] as String,
      eventId: json['event_id'] as String,
      imageUrl: json['image_url'] as String,
      videoUrl: json['video_url'] as String?,
      caption: json['caption'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      viewCount: json['view_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'organizer_id': organizerId,
      'event_id': eventId,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'view_count': viewCount,
      'is_active': isActive,
    };
    
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }
}