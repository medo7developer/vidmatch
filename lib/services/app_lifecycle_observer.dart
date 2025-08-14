import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  final String userId;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final VoidCallback? onAppPaused;
  final VoidCallback? onAppResumed;

  AppLifecycleObserver({
    required this.userId,
    this.onAppPaused,
    this.onAppResumed,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // التطبيق في الخلفية أو مغلق، قم بتنظيف الحالة
      _cleanupUserState();
      if (onAppPaused != null) onAppPaused!();
    } else if (state == AppLifecycleState.resumed) {
      // التطبيق استؤنف، قم بتحديث الحالة
      _updateUserState();
      if (onAppResumed != null) onAppResumed!();
    }
  }

  // تنظيف حالة المستخدم عند إغلاق التطبيق أو وضعه في الخلفية
  Future<void> _cleanupUserState() async {
    try {
      // تحديث حالة المستخدم إلى غير متاح
      await _database.child('users').child(userId).update({
        'isAvailable': false,
        'lastSeen': ServerValue.timestamp,
      });

      // إزالة المستخدم من غرفة الانتظار إذا كان فيها
      await _database.child('waiting_room').child(userId).remove();

      print('تم تنظيف حالة المستخدم عند إغلاق التطبيق أو وضعه في الخلفية');
    } catch (e) {
      print('خطأ في تنظيف حالة المستخدم: $e');
    }
  }

  // تحديث حالة المستخدم عند استئناف التطبيق
  Future<void> _updateUserState() async {
    try {
      // تحديث آخر ظهور للمستخدم
      await _database.child('users').child(userId).update({
        'lastSeen': ServerValue.timestamp,
        'isAvailable': true,
      });

      print('تم تحديث حالة المستخدم عند استئناف التطبيق');
    } catch (e) {
      print('خطأ في تحديث حالة المستخدم: $e');
    }
  }

  // تنظيف صريح عند إغلاق التطبيق
  Future<void> cleanupOnAppClose() async {
    return _cleanupUserState();
  }
}
