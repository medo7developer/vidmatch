import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/filter_preferences.dart';
import 'dart:math';

class SessionProvider with ChangeNotifier {
  final _database = FirebaseDatabase.instance.ref();

  UserModel? _currentUser;
  SessionModel? _currentSession;
  bool _isSearching = false;
  int _usersInWaitingRoom = 0;

  UserModel? get currentUser => _currentUser;
  SessionModel? get currentSession => _currentSession;
  bool get isSearching => _isSearching;
  bool get isInActiveSession => _currentSession != null;
  int get usersInWaitingRoom => _usersInWaitingRoom;
  Timer? _memoryCleanupTimer;

// إضافة استدعاء في البداية
  SessionProvider() {
    _listenToWaitingRoomCount();
    _startMemoryOptimization(); // إضافة هذا السطر
  }

  // إضافة هذه الدالة في SessionProvider
  void _startMemoryOptimization() {
    _memoryCleanupTimer?.cancel();

    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _optimizeMemoryUsage();
    });
  }

  void _optimizeMemoryUsage() {
    // تنظيف المتغيرات غير المستخدمة
    if (_currentSession == null) {
      // تنظيف أي مراجع لم تعد مطلوبة
    }
  }

  // التحقق من بنية قاعدة البيانات
  Future<void> checkDatabaseStructure() async {
    try {
      print('التحقق من بنية قاعدة البيانات...');

      final userSnapshot = await _database.child('users').get();
      print("هيكل المستخدمين: ${userSnapshot.exists ? 'موجود' : 'غير موجود'}");
      if (userSnapshot.exists) {
        final usersData = userSnapshot.value;
        if (usersData is Map) {
          print("عدد المستخدمين: ${usersData.length}");
        } else {
          print("بيانات المستخدمين ليست في تنسيق Map");
        }
      }

      final sessionSnapshot = await _database.child('sessions').get();
      print("هيكل الجلسات: ${sessionSnapshot.exists ? 'موجود' : 'غير موجود'}");

      final waitingRoomSnapshot = await _database.child('waiting_room').get();
      print("هيكل غرفة الانتظار: ${waitingRoomSnapshot.exists ? 'موجود' : 'غير موجود'}");

      // إنشاء الهياكل إذا لم تكن موجودة
      if (!userSnapshot.exists) {
        await _database.child('users').set({});
        print("تم إنشاء هيكل المستخدمين");
      }

      if (!sessionSnapshot.exists) {
        await _database.child('sessions').set({});
        print("تم إنشاء هيكل الجلسات");
      }

      if (!waitingRoomSnapshot.exists) {
        await _database.child('waiting_room').set({});
        print("تم إنشاء هيكل غرفة الانتظار");
      }
    } catch (e) {
      print("خطأ في التحقق من بنية قاعدة البيانات: $e");
    }
  }

  // تحديث حالة المستخدم في Firebase
  Future<void> updateUserStatus(String userId, UserModel user) async {
    try {
      final userRef = _database.child('users').child(userId);

      _currentUser = user;

      await userRef.set(user.toMap());
      print('تم تحديث حالة المستخدم $userId بنجاح');

      notifyListeners();
    } catch (e) {
      print('خطأ في تحديث حالة المستخدم: $e');
      throw Exception('فشل في تحديث حالة المستخدم: $e');
    }
  }

  // البحث عن مستخدم عشوائي مع دعم التصفية
  Future<String?> findRandomUser(String currentUserId, FilterPreferences filterPrefs) async {
    _isSearching = true;
    notifyListeners();

    try {
      // جلب قائمة المستخدمين المتوفرين
      final snapshot = await _database
          .child('users')
          .orderByChild('isAvailable')
          .equalTo(true)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        // تحويل آمن للبيانات
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<String> compatibleUserIds = [];

        // معالجة البيانات وتطبيق الفلاتر
        data.forEach((key, value) {
          if (key is String && value is Map && key != currentUserId) {
            try {
              // تحويل آمن من Map<dynamic, dynamic> إلى Map<String, dynamic>
              final Map<String, dynamic> userMap = {};
              (value as Map<dynamic, dynamic>).forEach((k, v) {
                userMap[k.toString()] = v;
              });

              // تحويل البيانات إلى نموذج المستخدم
              final user = UserModel.fromMap(userMap);
              bool isCompatible = true;

              // فلترة حسب الجنس
              if (filterPrefs.filterByGender &&
                  filterPrefs.preferredGender != 'الكل' &&
                  user.gender != filterPrefs.preferredGender) {
                isCompatible = false;
              }

              // فلترة حسب البلد
              if (isCompatible &&
                  filterPrefs.filterByCountry &&
                  filterPrefs.preferredCountry != 'الكل' &&
                  user.country != filterPrefs.preferredCountry) {
                isCompatible = false;
              }

              if (isCompatible) {
                compatibleUserIds.add(key);
              }
            } catch (e) {
              print('خطأ في معالجة بيانات المستخدم $key: $e');
            }
          }
        });

        print("المستخدمون المتاحون بعد الفلترة: ${compatibleUserIds.length}");

        if (compatibleUserIds.isNotEmpty) {
          // اختيار مستخدم عشوائي
          final random = Random();
          final randomIndex = random.nextInt(compatibleUserIds.length);
          final randomUserId = compatibleUserIds[randomIndex];

          print("تم اختيار المستخدم: $randomUserId");
          return randomUserId;
        } else {
          print("لا يوجد مستخدمون مطابقون للفلاتر");
        }
      } else {
        print("لا توجد بيانات مستخدمين متاحة");
      }

      return null;
    } catch (e) {
      print('خطأ في البحث عن مستخدم عشوائي: $e');
      return null;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

// في SessionProvider - تعديل دالة findMatchViaWaitingRoom
  Future<String?> findMatchViaWaitingRoom(String currentUserId, FilterPreferences filterPrefs) async {
    try {
      print('البحث عن مستخدم في غرفة الانتظار للمستخدم: $currentUserId');

      final waitingRoomRef = _database.child('waiting_room');

      // إجراء معاملة (transaction) لضمان التزامن الآمن
      final transactionResult = await waitingRoomRef.runTransaction((data) {
        if (data == null || !(data is Map)) {
          // غرفة الانتظار فارغة، أضف المستخدم الحالي
          return Transaction.success({
            currentUserId: {
              'userId': currentUserId,
              'timestamp': ServerValue.timestamp,
            }
          });
        }

        final waitingRoom = Map<String, dynamic>.from(data as Map);

        // البحث عن مستخدم متاح (استبعاد المستخدم الحالي)
        String? matchedUser;
        for (String userId in waitingRoom.keys) {
          if (userId != currentUserId) {
            matchedUser = userId;
            break;
          }
        }

        if (matchedUser != null) {
          // إزالة المستخدم المطابق وإضافة المستخدم الحالي كمؤقت
          waitingRoom.remove(matchedUser);
          waitingRoom[currentUserId] = {
            'userId': currentUserId,
            'timestamp': ServerValue.timestamp,
            'matched_with': matchedUser,
          };
          return Transaction.success(waitingRoom);
        } else {
          // لا يوجد مستخدمون متاحون، أضف المستخدم الحالي فقط
          waitingRoom[currentUserId] = {
            'userId': currentUserId,
            'timestamp': ServerValue.timestamp,
          };
          return Transaction.success(waitingRoom);
        }
      });

      if (transactionResult.committed) {
        final updatedData = transactionResult.snapshot.value;
        if (updatedData is Map) {
          final myData = updatedData[currentUserId];
          if (myData is Map && myData['matched_with'] != null) {
            final matchedUserId = myData['matched_with'].toString();
            print('تم العثور على مطابقة في المعاملة: $matchedUserId');

            // إزالة البيانات المؤقتة
            await waitingRoomRef.child(currentUserId).remove();

            return matchedUserId;
          }
        }
      }

      print('تم إضافة المستخدم $currentUserId إلى غرفة الانتظار');
      return null;
    } catch (e) {
      print('خطأ في غرفة الانتظار: $e');
      return null;
    }
  }

  // الاستماع لعدد المستخدمين في غرفة الانتظار
  void _listenToWaitingRoomCount() {
    _database.child('waiting_room').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value;
        if (data is Map) {
          _usersInWaitingRoom = data.length;
        } else {
          _usersInWaitingRoom = 0;
        }
        notifyListeners();
      } else {
        _usersInWaitingRoom = 0;
        notifyListeners();
      }
    });
  }

// في SessionProvider - تعديل دالة createSession
  Future<SessionModel?> createSession(String hostId, String guestId) async {
    try {
      print('إنشاء جلسة جديدة بين المضيف $hostId والضيف $guestId');

      // إنشاء مرجع جديد في Firebase
      final sessionRef = _database.child('sessions').push();
      final sessionId = sessionRef.key!;

      // إنشاء نموذج الجلسة
      final session = SessionModel(
        id: sessionId,
        hostId: hostId,
        guestId: guestId,
        createdAt: DateTime.now(),
      );

      // خطوة 1: حفظ الجلسة في Firebase أولاً
      await sessionRef.set(session.toMap());
      print('تم حفظ الجلسة في Firebase: $sessionId');

      // خطوة 2: إشعار الضيف بشكل صريح قبل تحديث حالة المستخدمين
      await _notifyGuestOfSession(guestId, sessionId, hostId);

      // خطوة 3: تحديث حالة المستخدمين بعد إنشاء الجلسة
      await _database.child('users').child(hostId).update({'isAvailable': false});
      await _database.child('users').child(guestId).update({'isAvailable': false});

      // خطوة 4: إزالة المستخدمين من غرفة الانتظار
      await _database.child('waiting_room').child(hostId).remove();
      await _database.child('waiting_room').child(guestId).remove();

      // تحديث المتغير المحلي للجلسة
      _currentSession = session;
      notifyListeners();

      print('تم إنشاء الجلسة بنجاح: ${session.id}');
      return session;
    } catch (e) {
      print('خطأ في إنشاء جلسة: $e');
      return null;
    }
  }

// دالة جديدة لإشعار الضيف
  Future<void> _notifyGuestOfSession(String guestId, String sessionId, String hostId) async {
    try {
      // إنشاء إشعار للضيف في مسار منفصل
      await _database.child('session_notifications').child(guestId).set({
        'sessionId': sessionId,
        'hostId': hostId,
        'timestamp': ServerValue.timestamp,
        'type': 'new_session'
      });

      print('تم إرسال إشعار الجلسة للضيف: $guestId');
    } catch (e) {
      print('خطأ في إرسال إشعار الجلسة: $e');
    }
  }

// تعديل دالة endSession في SessionProvider
  Future<void> endSession(String userId) async {
    if (_currentSession != null) {
      try {
        print('إنهاء الجلسة: ${_currentSession!.id}');

        final sessionRef = _database.child('sessions').child(_currentSession!.id);

        // 1. إرسال إشارة إنهاء فورية للطرف الآخر
        await sessionRef.update({
          'isActive': false,
          'endedBy': userId,
          'endedAt': ServerValue.timestamp,
        });

        // 2. إرسال إشعار خاص للطرف الآخر
        await sessionRef.child('callEnded').set({
          'endedBy': userId,
          'timestamp': ServerValue.timestamp,
          'reason': 'user_ended'
        });

        // 3. تحديث حالة المستخدم
        if (_currentUser != null) {
          await _database.child('users').child(userId).update({
            'isAvailable': true,
            'lastSeen': ServerValue.timestamp,
          });
        } else {
          await _database.child('users').child(userId).update({
            'isAvailable': true,
            'lastSeen': ServerValue.timestamp,
          });
        }

        // 4. تنظيف البيانات المرتبطة بالجلسة
        await _cleanupSessionData(_currentSession!.id);

        // 5. إزالة المستخدم من غرفة الانتظار
        await _database.child('waiting_room').child(userId).remove();

        _currentSession = null;
        notifyListeners();

        print('تم إنهاء الجلسة بنجاح');
      } catch (e) {
        print('خطأ في إنهاء الجلسة: $e');
      }
    } else {
      // التأكد من تنظيف حالة المستخدم حتى لو لم تكن هناك جلسة
      try {
        await _database.child('waiting_room').child(userId).remove();
        await _database.child('users').child(userId).update({
          'isAvailable': true,
          'lastSeen': ServerValue.timestamp,
        });
      } catch (e) {
        print('خطأ في تنظيف حالة المستخدم: $e');
      }
    }
  }

// دالة جديدة لتنظيف بيانات الجلسة
  Future<void> _cleanupSessionData(String sessionId) async {
    try {
      // حذف مرشحي ICE والبيانات المؤقتة
      await _database.child('sessions').child(sessionId).child('candidates').remove();
      await _database.child('sessions').child(sessionId).child('offer').remove();
      await _database.child('sessions').child(sessionId).child('answer').remove();
      await _database.child('sessions').child(sessionId).child('requestAnswer').remove();

      print('تم تنظيف بيانات الجلسة: $sessionId');
    } catch (e) {
      print('خطأ في تنظيف بيانات الجلسة: $e');
    }
  }

  // استمع إلى تغييرات الجلسة
  void listenToSessionChanges(String sessionId, Function(SessionModel) onUpdate) {
    _database.child('sessions').child(sessionId).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

          // تحويل البيانات إلى نموذج الجلسة
          final session = SessionModel(
            id: sessionId,
            hostId: data['hostId'] ?? '',
            guestId: data['guestId'] ?? '',
            createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
            isActive: data['isActive'] ?? true,
          );

          print('تم تحديث الجلسة: ${session.id}, نشطة: ${session.isActive}');

          // تحقق مما إذا كانت الجلسة لا تزال نشطة
          if (!session.isActive) {
            _currentSession = null;
            notifyListeners();
          } else {
            _currentSession = session;
            onUpdate(session);
          }
        } catch (e) {
          print('خطأ في معالجة بيانات الجلسة: $e');
        }
      }
    });
  }

// التنظيف عند الخروج أو تدمير الـ Provider
  Future<void> cleanup() async {
    try {
      if (_currentUser != null) {
        // إزالة المستخدم من غرفة الانتظار
        await _database.child('waiting_room').child(_currentUser!.id).remove();

        // تعيين حالة المستخدم إلى غير متاح عند الخروج من التطبيق
        await _database.child('users').child(_currentUser!.id).update({
          'isAvailable': false,
          'lastSeen': ServerValue.timestamp,
        });
      }

      if (_currentSession != null) {
        // إنهاء أي جلسة حالية
        await _database.child('sessions').child(_currentSession!.id).update({
          'isActive': false,
        });

        // تنظيف مرشحي ICE للجلسة لتوفير مساحة
        await _database.child('sessions').child(_currentSession!.id).child('candidates').remove();
      }
    } catch (e) {
      print('خطأ في تنظيف الحالة: $e');
    }
  }
}
