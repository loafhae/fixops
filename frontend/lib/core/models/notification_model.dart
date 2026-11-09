class NotificationModel {
  final String id;
  final String? ticketId;
  final String eventType;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.ticketId,
    required this.eventType,
    required this.message,
    required this.createdAt,
    required this.readAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      ticketId: json['ticket_id'],
      eventType: json['event_type'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'])
          : null,
    );
  }
}
