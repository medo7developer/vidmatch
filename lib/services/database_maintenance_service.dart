import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_deletion_service.dart';

class DatabaseMaintenanceService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Timer? _maintenanceTimer;

  // مفتاح للتخزين المحلي لآخر وقت تم فيه التنظيف
  static const String _lastCleanupKey = 'last_database_cleanup';

  // بدء خدمة الصيانة الدورية
  void startPeriodicMaintenance(Duration interval) {
    _maintenanceTimer?.cancel();

    _maintenanceTimer = Timer.periodic(interval, (_) {
      _performMaintenance();
    });
  }

  // إيقاف خدمة الصيانة
  void stopMaintenance() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = null;
  }

  // تنفيذ الصيانة فوراً
  Future<void> performMaintenanceNow() async {
    return _performMaintenance();
  }

  // التحقق من حاجة التطبيق للصيانة
  Future<bool> shouldPerformMaintenance() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCleanup = prefs.getInt(_lastCleanupKey) ?? 0;

    // التنظيف مرة كل 6 ساعات على الأقل
    final sixHoursAgo = DateTime.now().millisecondsSinceEpoch - (6 * 60 * 60 * 1000);
    return lastCleanup < sixHoursAgo;
  }

  Future<void> _processAccountDeletionRequests() async {
    try {
      final accountDeletionService = AccountDeletionService();
      final now = DateTime.now().millisecondsSinceEpoch;

      // الحصول على طلبات الحذف النشطة التي انتهت مهلتها
      final snapshot = await _database.child('deletion_requests')
          .orderByChild('executionDate')
          .endAt(now)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final requests = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in requests.entries) {
          final userId = entry.key;
          final requestData = Map<String, dynamic>.from(entry.value as Map);

          // التحقق مما إذا كان الطلب لا يزال نشطًا
          if (requestData['isActive'] == true) {
            print('تنفيذ طلب حذف الحساب للمستخدم: $userId');
            await accountDeletionService.executeAccountDeletion(userId);
          }
        }
      }
    } catch (e) {
      print('خطأ في معالجة طلبات حذف الحساب: $e');
    }
  }

  // تنفيذ عمليات الصيانة المختلفة
  Future<void> _performMaintenance() async {
    try {
      print('بدء عملية صيانة قاعدة البيانات...');

      // التحقق من ضرورة التنظيف
      if (!await shouldPerformMaintenance()) {
        print('تم التنظيف مؤخراً، لا حاجة للتنظيف الآن');
        return;
      }

      // 1. تنظيف غرفة الانتظار من المستخدمين غير النشطين
      await _cleanupWaitingRoom();
      await _processAccountDeletionRequests();

      // 2. تحديث حالة المستخدمين غير النشطين
      await _updateInactiveUsers();

      // 3. تنظيف الجلسات القديمة
      await _cleanupOldSessions();

      // تسجيل وقت التنظيف
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCleanupKey, DateTime.now().millisecondsSinceEpoch);

      print('اكتملت عملية صيانة قاعدة البيانات بنجاح');
    } catch (e) {
      print('خطأ أثناء تنفيذ الصيانة: $e');
    }
  }

  // تنظيف غرفة الانتظار
  Future<void> _cleanupWaitingRoom() async {
    try {
      final hourAgo = DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000);

      final snapshot = await _database.child('waiting_room').get();
      if (!snapshot.exists || snapshot.value == null) return;

      final waitingRoom = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Future<void>> deletionOperations = [];
      int cleanupCount = 0;

      waitingRoom.forEach((userId, userData) {
        if (userData is Map) {
          final timestamp = userData['timestamp'] as int? ?? 0;
          if (timestamp < hourAgo) {
            deletionOperations.add(_database.child('waiting_room').child(userId).remove());
            cleanupCount++;
          }
        }
      });

      if (deletionOperations.isNotEmpty) {
        await Future.wait(deletionOperations);
        print('تم تنظيف $cleanupCount مستخدم من غرفة الانتظار');
      }
    } catch (e) {
      print('خطأ في تنظيف غرفة الانتظار: $e');
    }
  }

  // تحديث حالة المستخدمين غير النشطين
  Future<void> _updateInactiveUsers() async {
    try {
      final twoHoursAgo = DateTime.now().millisecondsSinceEpoch - (2 * 60 * 60 * 1000);

      final snapshot = await _database.child('users').get();
      if (!snapshot.exists || snapshot.value == null) return;

      final users = Map<String, dynamic>.from(snapshot.value as Map);
      final Map<String, dynamic> updates = {};
      int updatedCount = 0;

      users.forEach((userId, userData) {
        if (userData is Map) {
          final lastSeen = userData['lastSeen'] as int? ?? 0;
          final isAvailable = userData['isAvailable'] as bool? ?? false;

          if (lastSeen < twoHoursAgo && isAvailable) {
            updates['users/$userId/isAvailable'] = false;
            updatedCount++;
          }
        }
      });

      if (updates.isNotEmpty) {
        await _database.update(updates);
        print('تم تحديث حالة $updatedCount مستخدم غير نشط');
      }
    } catch (e) {
      print('خطأ في تحديث حالة المستخدمين: $e');
    }
  }

  // تنظيف الجلسات القديمة غير النشطة
  Future<void> _cleanupOldSessions() async {
    try {
      final threeHoursAgo = DateTime.now().millisecondsSinceEpoch - (3 * 60 * 60 * 1000);

      final snapshot = await _database.child('sessions').get();
      if (!snapshot.exists || snapshot.value == null) return;

      final sessions = Map<String, dynamic>.from(snapshot.value as Map);
      final Map<String, dynamic> updates = {};
      int updatedCount = 0;

      sessions.forEach((sessionId, sessionData) {
        if (sessionData is Map) {
          final createdAt = sessionData['createdAt'] as int? ?? 0;
          final isActive = sessionData['isActive'] as bool? ?? false;

          if ((createdAt < threeHoursAgo || !isActive) && isActive) {
            updates['sessions/$sessionId/isActive'] = false;
            updatedCount++;
          }
        }
      });

      if (updates.isNotEmpty) {
        await _database.update(updates);
        print('تم تحديث $updatedCount جلسة قديمة');
      }
    } catch (e) {
      print('خطأ في تنظيف الجلسات القديمة: $e');
    }
  }
}
