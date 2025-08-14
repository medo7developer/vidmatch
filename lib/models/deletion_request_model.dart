class DeletionRequestModel {
  final String userId;
  final DateTime requestDate;
  final DateTime executionDate;
  final bool isActive;

  DeletionRequestModel({
    required this.userId,
    required this.requestDate,
    required this.executionDate,
    this.isActive = true,
  });

  factory DeletionRequestModel.fromMap(Map<String, dynamic> map) {
    return DeletionRequestModel(
      userId: map['userId'] ?? '',
      requestDate: DateTime.fromMillisecondsSinceEpoch(map['requestDate'] ?? 0),
      executionDate: DateTime.fromMillisecondsSinceEpoch(map['executionDate'] ?? 0),
      isActive: map['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'requestDate': requestDate.millisecondsSinceEpoch,
      'executionDate': executionDate.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  // التحقق إذا كان الطلب لا يزال في فترة التراجع
  bool get isWithinCancellationPeriod {
    final now = DateTime.now();
    return now.isBefore(executionDate);
  }

  // حساب الوقت المتبقي بالساعات
  int get remainingHours {
    final now = DateTime.now();
    final difference = executionDate.difference(now);
    return difference.inHours;
  }

  DeletionRequestModel copyWith({
    String? userId,
    DateTime? requestDate,
    DateTime? executionDate,
    bool? isActive,
  }) {
    return DeletionRequestModel(
      userId: userId ?? this.userId,
      requestDate: requestDate ?? this.requestDate,
      executionDate: executionDate ?? this.executionDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
