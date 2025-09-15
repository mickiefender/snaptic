class Event {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final DateTime date;
  final String imageUrl;
  final DateTime createdAt;
  final String? location;
  final String? venue;
  final double? ticketPrice;
  final int? maxAttendees;
  final String? category;
  final List<String>? tags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int bookmarkCount;
  final int currentAttendees;
  final String? organizerName;
  final String? organizerImageUrl;
  bool isLikedByUser;
  bool isBookmarkedByUser;
  final String status;

  Event({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.createdAt,
    this.location,
    this.venue,
    this.ticketPrice,
    this.maxAttendees,
    this.category,
    this.tags,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.bookmarkCount = 0,
    this.currentAttendees = 0,
    this.organizerName,
    this.organizerImageUrl,
    this.isLikedByUser = false,
    this.isBookmarkedByUser = false,
    this.status = 'published',
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      organizerId: json['organizer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['start_date'] as String? ?? json['date'] as String),
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      location: json['location'] as String?,
      venue: json['venue'] as String?,
      ticketPrice: json['ticket_price'] != null 
          ? (json['ticket_price'] as num).toDouble() 
          : null,
      maxAttendees: json['max_attendees'] as int?,
      category: json['category'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      bookmarkCount: json['bookmark_count'] as int? ?? 0,
      currentAttendees: json['current_attendees'] as int? ?? 0,
      organizerName: json['organizer_name'] as String?,
      organizerImageUrl: json['organizer_image_url'] as String?,
      isLikedByUser: json['is_liked_by_user'] as bool? ?? false,
      isBookmarkedByUser: json['is_bookmarked_by_user'] as bool? ?? false,
      status: json['status'] as String? ?? 'published',
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'organizer_id': organizerId,
      'title': title,
      'description': description,
      'start_date': date.toIso8601String(),
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'location': location,
      'venue': venue,
      'ticket_price': ticketPrice,
      'max_attendees': maxAttendees,
      'category': category,
      'tags': tags,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'bookmark_count': bookmarkCount,
      'current_attendees': currentAttendees,
      'status': status,
    };
    
    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}