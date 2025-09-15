class Ticket {
  static const String statusPurchased = 'purchased';
  static const String statusActive = 'active';
  static const String statusCheckedIn = 'checked_in';
  static const String statusCancelled = 'cancelled';
  static const String statusRefunded = 'refunded';
  
  final String id;
  final String uid;
  final String eventId;
  final String userId;
  final String status;
  final DateTime createdAt;
  final DateTime? checkedInAt;
  final String? paymentReference;
  final double? amount;

  Ticket({
    required this.id,
    required this.uid,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.checkedInAt,
    this.paymentReference,
    this.amount,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      uid: json['uid'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      checkedInAt: json['checked_in_at'] != null 
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      paymentReference: json['payment_reference'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'event_id': eventId,
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'checked_in_at': checkedInAt?.toIso8601String(),
      'payment_reference': paymentReference,
      'amount': amount,
    };
  }

  bool get isPurchased => status == statusPurchased;
  bool get isActive => status == statusActive;
  bool get isCheckedIn => status == statusCheckedIn;
}