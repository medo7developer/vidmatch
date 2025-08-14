import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AppStateManager with WidgetsBindingObserver {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  final NotificationService _notificationService = NotificationService();
  bool _isAppInBackground = false;
  DateTime? _lastBackgroundTime;

  // تهيئة المدير
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    await _notificationService.initialize();
    await _setupDailyNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _onAppPaused();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  // عند استئناف التطبيق
  void _onAppResumed() async {
    print('التطبيق تم استئنافه');
    _isAppInBackground = false;

    // تحديث آخر وقت لفتح التطبيق
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_app_open', DateTime.now().millisecondsSinceEpoch);

    // إعادة جدولة الإشعارات (في حالة تم تغيير الوقت)
    await _setupDailyNotifications();
  }

  // عند وضع التطبيق في الخلفية
  void _onAppPaused() async {
    print('التطبيق في الخلفية');
    _isAppInBackground = true;
    _lastBackgroundTime = DateTime.now();

    // حفظ وقت وضع التطبيق في الخلفية
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_background_time', _lastBackgroundTime!.millisecondsSinceEpoch);
  }

  // إعداد الإشعارات اليومية
  Future<void> _setupDailyNotifications() async {
    await _notificationService.scheduleDailyNotifications();
  }

  // تفعيل/تعطيل الإشعارات
  Future<void> toggleNotifications(bool enabled) async {
    await _notificationService.setNotificationsEnabled(enabled);
  }

  // إرسال إشعار اختبار
  Future<void> sendTestNotification() async {
    await _notificationService.sendTestNotification();
  }

  // الحصول على حالة الإشعارات
  Future<bool> getNotificationStatus() async {
    return await _notificationService.areNotificationsEnabled();
  }

  // إحصائيات الاستخدام
  Future<Map<String, dynamic>> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpen = prefs.getInt('last_app_open') ?? 0;
    final lastBackground = prefs.getInt('last_background_time') ?? 0;

    return {
      'lastOpenTime': lastOpen > 0 ? DateTime.fromMillisecondsSinceEpoch(lastOpen) : null,
      'lastBackgroundTime': lastBackground > 0 ? DateTime.fromMillisecondsSinceEpoch(lastBackground) : null,
      'isCurrentlyInBackground': _isAppInBackground,
    };
  }

  // تنظيف المدير
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}