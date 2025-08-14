class SessionModel {
  final String id;
  final String hostId;
  final String guestId;
  final DateTime createdAt;
  final bool isActive;

  SessionModel({
    required this.id,
    required this.hostId,
    required this.guestId,
    required this.createdAt,
    this.isActive = true,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? '',
      hostId: map['hostId'] ?? '',
      guestId: map['guestId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'guestId': guestId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }
}
