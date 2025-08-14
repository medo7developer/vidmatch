import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserCleanupService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // تنظيف بيانات المستخدم الحالي عند بدء التطبيق
  Future<void> cleanupCurrentUser(String userId) async {
    try {
      // إزالة المستخدم من غرفة الانتظار (في حال تم إغلاق التطبيق فجأة)
      await _database.child('waiting_room').child(userId).remove();

      // تحديث آخر ظهور للمستخدم
      await _database.child('users').child(userId).update({
        'lastSeen': ServerValue.timestamp,
        'isAvailable': true,
      });

      print('تم تنظيف بيانات المستخدم الحالي: $userId');
    } catch (e) {
      print('خطأ في تنظيف بيانات المستخدم: $e');
    }
  }

  // إنهاء جلسات المستخدم العالقة
  Future<void> cleanupUserSessions(String userId) async {
    try {
      // البحث عن الجلسات التي يكون المستخدم مضيفاً فيها
      final hostSessionsSnapshot = await _database.child('sessions')
          .orderByChild('hostId')
          .equalTo(userId)
          .get();

      if (hostSessionsSnapshot.exists && hostSessionsSnapshot.value != null) {
        final sessions = Map<String, dynamic>.from(hostSessionsSnapshot.value as Map);
        final updates = <String, dynamic>{};

        sessions.forEach((sessionId, data) {
          if (data is Map && (data['isActive'] ?? false)) {
            updates['sessions/$sessionId/isActive'] = false;
          }
        });

        if (updates.isNotEmpty) {
          await _database.update(updates);
          print('تم إنهاء الجلسات العالقة للمستخدم كمضيف');
        }
      }

      // البحث عن الجلسات التي يكون المستخدم ضيفاً فيها
      final guestSessionsSnapshot = await _database.child('sessions')
          .orderByChild('guestId')
          .equalTo(userId)
          .get();

      if (guestSessionsSnapshot.exists && guestSessionsSnapshot.value != null) {
        final sessions = Map<String, dynamic>.from(guestSessionsSnapshot.value as Map);
        final updates = <String, dynamic>{};

        sessions.forEach((sessionId, data) {
          if (data is Map && (data['isActive'] ?? false)) {
            updates['sessions/$sessionId/isActive'] = false;
          }
        });

        if (updates.isNotEmpty) {
          await _database.update(updates);
          print('تم إنهاء الجلسات العالقة للمستخدم كضيف');
        }
      }
    } catch (e) {
      print('خطأ في تنظيف جلسات المستخدم: $e');
    }
  }
}
