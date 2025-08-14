class ReportModel {
  final String id;
  final String reporterId; // معرف مقدم البلاغ
  final String reportedUserId; // معرف المستخدم المُبلغ عنه
  final String reason; // سبب البلاغ
  final String details; // تفاصيل إضافية
  final DateTime createdAt;
  final String sessionId; // معرف الجلسة
  final bool isResolved; // هل تمت معالجة التقرير

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.details = '',
    required this.createdAt,
    required this.sessionId,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'details': details,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'sessionId': sessionId,
      'isResolved': isResolved,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: map['reason'] ?? '',
      details: map['details'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      sessionId: map['sessionId'] ?? '',
      isResolved: map['isResolved'] ?? false,
    );
  }
}
