import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/filter_preferences.dart';

class FirebaseService {
  final _database = FirebaseDatabase.instance.ref();

  // تحديث حالة المستخدم
  Future<void> updateUserStatus(UserModel user) async {
    final userRef = _database.child('users').child(user.id);
    await userRef.set(user.toMap());
  }

  // الحصول على معلومات المستخدم بواسطة المعرف
  Future<UserModel?> getUserById(String userId) async {
    final snapshot = await _database.child('users').child(userId).get();

    if (snapshot.exists) {
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel.fromMap(userData);
    }

    return null;
  }

  // إنشاء أو تحديث مستخدم
  Future<void> createOrUpdateUser(UserModel user) async {
    await _database.child('users').child(user.id).set(user.toMap());
  }

  // البحث عن مستخدمين متاحين حسب التفضيلات
  Future<List<UserModel>> findAvailableUsers(FilterPreferences preferences, String excludeUserId) async {
    final snapshot = await _database
        .child('users')
        .orderByChild('isAvailable')
        .equalTo(true)
        .get();

    if (!snapshot.exists) {
      return [];
    }

    final List<UserModel> users = [];
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

    data.forEach((key, value) {
      if (key != excludeUserId && value is Map) {
        final user = UserModel.fromMap(Map<String, dynamic>.from(value));

        bool isCompatible = true;

        // فلترة حسب الجنس
        if (preferences.filterByGender &&
            preferences.preferredGender != 'الكل' &&
            user.gender != preferences.preferredGender) {
          isCompatible = false;
        }

        // فلترة حسب البلد
        if (preferences.filterByCountry &&
            preferences.preferredCountry != 'الكل' &&
            user.country != preferences.preferredCountry) {
          isCompatible = false;
        }

        if (isCompatible) {
          users.add(user);
        }
      }
    });

    return users;
  }

  // إضافة مستخدم إلى غرفة الانتظار
  Future<void> addUserToWaitingRoom(String userId, FilterPreferences preferences) async {
    final data = {
      'userId': userId,
      'timestamp': ServerValue.timestamp,
      'preferences': preferences.toMap(),
    };

    await _database.child('waiting_room').child(userId).set(data);
  }

  // إزالة مستخدم من غرفة الانتظار
  Future<void> removeUserFromWaitingRoom(String userId) async {
    await _database.child('waiting_room').child(userId).remove();
  }

  // البحث عن مستخدم متوافق في غرفة الانتظار
  Future<String?> findCompatibleUserInWaitingRoom(UserModel currentUser, FilterPreferences preferences) async {
    final snapshot = await _database.child('waiting_room').get();

    if (snapshot.exists && snapshot.value != null) {
      final waitingRoomData = snapshot.value;
      if (waitingRoomData is Map) {
        String? bestMatch;
        int oldestTimestamp = DateTime.now().millisecondsSinceEpoch;

        waitingRoomData.forEach((key, value) {
          if (key != currentUser.id && value is Map) {
            final waitingUser = Map<String, dynamic>.from(value);
            final String waitingUserId = waitingUser['userId'] ?? '';
            final int timestamp = waitingUser['timestamp'] ?? 0;
            final Map<dynamic, dynamic>? waitingUserPrefs = waitingUser['preferences'];

            bool isCompatible = true;

            // تطبيق فلاتر المستخدم الحالي
            if (preferences.filterByGender && preferences.preferredGender != 'الكل') {
              // التحقق من جنس المستخدم المنتظر
              getUserById(waitingUserId).then((foundUser) {
                if (foundUser != null && foundUser.gender != preferences.preferredGender) {
                  isCompatible = false;
                }
              });
            }

            if (preferences.filterByCountry && preferences.preferredCountry != 'الكل') {
              // التحقق من بلد المستخدم المنتظر
              getUserById(waitingUserId).then((foundUser) {
                if (foundUser != null && foundUser.country != preferences.preferredCountry) {
                  isCompatible = false;
                }
              });
            }

            // تحقق من توافق تفضيلات المستخدم المنتظر
            if (waitingUserPrefs != null) {
              final waitingPrefs = FilterPreferences.fromMap(Map<String, dynamic>.from(waitingUserPrefs));

              if (waitingPrefs.filterByGender && waitingPrefs.preferredGender != 'الكل' &&
                  currentUser.gender != waitingPrefs.preferredGender) {
                isCompatible = false;
              }

              if (waitingPrefs.filterByCountry && waitingPrefs.preferredCountry != 'الكل' &&
                  currentUser.country != waitingPrefs.preferredCountry) {
                isCompatible = false;
              }
            }

            if (isCompatible && timestamp < oldestTimestamp) {
              oldestTimestamp = timestamp;
              bestMatch = waitingUserId;
            }
          }
        });

        return bestMatch;
      }
    }

    return null;
  }

  // إنشاء جلسة جديدة
  Future<SessionModel> createSession(String hostId, String guestId) async {
    final sessionRef = _database.child('sessions').push();
    final sessionId = sessionRef.key!;

    final session = SessionModel(
      id: sessionId,
      hostId: hostId,
      guestId: guestId,
      createdAt: DateTime.now(),
    );

    await sessionRef.set(session.toMap());
    return session;
  }

  // إنهاء جلسة
  Future<void> endSession(String sessionId) async {
    await _database.child('sessions').child(sessionId).update({'isActive': false});
  }

  // إضافة مرشح ICE
  Future<void> addIceCandidate(String sessionId, String role, Map<String, dynamic> candidate) async {
    await _database
        .child('sessions')
        .child(sessionId)
        .child('candidates')
        .child(role)
        .push()
        .set(candidate);
  }

  // تحديث وصف الجلسة
  Future<void> updateSessionDescription(String sessionId, String type, Map<String, dynamic> description) async {
    await _database
        .child('sessions')
        .child(sessionId)
        .child(type)
        .set(description);
  }

  // الاستماع لتغييرات وصف الجلسة
  Stream<DatabaseEvent> listenToSessionDescription(String sessionId, String type) {
    return _database
        .child('sessions')
        .child(sessionId)
        .child(type)
        .onValue;
  }

  // الاستماع لمرشحي ICE
  Stream<DatabaseEvent> listenToIceCandidates(String sessionId, String role) {
    return _database
        .child('sessions')
        .child(sessionId)
        .child('candidates')
        .child(role)
        .onChildAdded;
  }

  // الاستماع لعدد المستخدمين في غرفة الانتظار
  Stream<DatabaseEvent> listenToWaitingRoomCount() {
    return _database.child('waiting_room').onValue;
  }

  // تنظيف المستخدمين غير النشطين
  Future<void> cleanupInactiveUsers(Duration threshold) async {
    final now = DateTime.now();
    final thresholdTime = now.subtract(threshold);

    final snapshot = await _database.child('users').get();

    if (snapshot.exists) {
      final users = Map<String, dynamic>.from(snapshot.value as Map);

      for (final entry in users.entries) {
        final userId = entry.key;
        final userData = Map<String, dynamic>.from(entry.value);
        final lastSeen = DateTime.fromMillisecondsSinceEpoch(userData['lastSeen'] ?? 0);

        if (lastSeen.isBefore(thresholdTime)) {
          // حذف المستخدم غير النشط من غرفة الانتظار
          await _database.child('waiting_room').child(userId).remove();

          // تعيين المستخدم كغير متاح
          await _database.child('users').child(userId).update({'isAvailable': false});
        }
      }
    }
  }

  // تنظيف الجلسات القديمة
  Future<void> cleanupOldSessions(Duration threshold) async {
    final now = DateTime.now();
    final thresholdTime = now.subtract(threshold);

    final snapshot = await _database.child('sessions').get();

    if (snapshot.exists) {
      final sessions = Map<String, dynamic>.from(snapshot.value as Map);

      for (final entry in sessions.entries) {
        final sessionId = entry.key;
        final sessionData = Map<String, dynamic>.from(entry.value);
        final createdAt = DateTime.fromMillisecondsSinceEpoch(sessionData['createdAt'] ?? 0);

        if (createdAt.isBefore(thresholdTime)) {
          // تعيين الجلسة القديمة كغير نشطة
          await _database.child('sessions').child(sessionId).update({'isActive': false});
        }
      }
    }
  }
}
