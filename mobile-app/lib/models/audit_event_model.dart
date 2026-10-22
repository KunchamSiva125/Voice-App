class AuditEventModel {
  final String id;
  final String actorUserId;
  final String actorUsername;
  final String action;
  final String entityType;
  final String entityId;
  final String occurredAt;
  final String reason;
  final Map<String, dynamic>? beforeSnapshot;
  final Map<String, dynamic>? afterSnapshot;
  final String? clientIp;

  AuditEventModel({
    required this.id,
    required this.actorUserId,
    required this.actorUsername,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.occurredAt,
    required this.reason,
    this.beforeSnapshot,
    this.afterSnapshot,
    this.clientIp,
  });

  factory AuditEventModel.fromJson(Map<String, dynamic> json) {
    return AuditEventModel(
      id: json['id'] ?? '',
      actorUserId: json['actorUserId'] ?? '',
      actorUsername: json['actorUsername'] ?? '',
      action: json['action'] ?? '',
      entityType: json['entityType'] ?? '',
      entityId: json['entityId'] ?? '',
      occurredAt: json['occurredAt'] ?? '',
      reason: json['reason'] ?? '',
      beforeSnapshot: json['beforeSnapshot'] is Map<String, dynamic> ? json['beforeSnapshot'] : null,
      afterSnapshot: json['afterSnapshot'] is Map<String, dynamic> ? json['afterSnapshot'] : null,
      clientIp: json['clientIp'],
    );
  }
}
