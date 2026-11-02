class AuditLogModel {
  final String id;
  final String? userId;
  final String? userEmail;
  final String action;
  final String? targetTicketId;
  final String? details;
  final String? ipAddress;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    this.userId,
    this.userEmail,
    required this.action,
    this.targetTicketId,
    this.details,
    this.ipAddress,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] ?? '',
      userId: json['user_id'],
      userEmail: json['user_email'],
      action: json['action'] ?? '',
      targetTicketId: json['target_ticket_id'],
      details: json['details'],
      ipAddress: json['ip_address'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

