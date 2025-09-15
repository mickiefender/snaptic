class UserProfile {
  final String userId; // Supabase auth user ID (UUID)
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? location;
  final String? website;
  final Map<String, dynamic>? socialLinks;
  final Map<String, dynamic>? preferences;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.location,
    this.website,
    this.socialLinks,
    this.preferences,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

    factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
    Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
      'bio': bio,
      'phone': phone,
      'location': location,
      'website': website,
      'social_links': socialLinks,
      'preferences': preferences,
      'is_verified': isVerified,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
  bool get isOrganizer => role == 'organizer';
  bool get isAttendee => role == 'attendee';

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? location,
    String? website,
    Map<String, dynamic>? socialLinks,
    Map<String, dynamic>? preferences,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      socialLinks: socialLinks ?? this.socialLinks,
      preferences: preferences ?? this.preferences,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}