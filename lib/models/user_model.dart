class UserModel {
  final String id;
  final String name;
  final String country;
  final String gender;
  final bool isAvailable;
  final DateTime lastSeen;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.country,
    required this.gender,
    this.isAvailable = true,
    required this.lastSeen,
    this.preferences,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'مستخدم',
      country: map['country'] ?? 'غير محدد',
      gender: map['gender'] ?? 'غير محدد',
      isAvailable: map['isAvailable'] == true, // تحويل آمن للقيم المختلفة
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
          map['lastSeen'] is int ? map['lastSeen'] : DateTime.now().millisecondsSinceEpoch
      ),
      preferences: map['preferences'] is Map ?
      Map<String, dynamic>.from(map['preferences'] as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'gender': gender,
      'isAvailable': isAvailable,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'preferences': preferences ?? {},
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? country,
    String? gender,
    bool? isAvailable,
    DateTime? lastSeen,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      isAvailable: isAvailable ?? this.isAvailable,
      lastSeen: lastSeen ?? this.lastSeen,
      preferences: preferences ?? this.preferences,
    );
  }
}
