import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/foundation.dart'; // مهم جدًا

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // قائمة رسائل التشجيع
  static const List<String> _encouragementMessages = [
    '👋 مرحباً! هناك أشخاص جدد ينتظرون التحدث معك',
    '🌟 اكتشف أصدقاء جدد من حول العالم الآن!',
    '💬 وقت الدردشة! ابدأ محادثة ممتعة مع شخص جديد',
    '🎥 دردشة فيديو ممتعة تنتظرك! انضم الآن',
    '🌍 تواصل مع أشخاص من ثقافات مختلفة اليوم',
    '✨ لحظات رائعة تنتظرك في دردشة الفيديو',
    '🎊 ابدأ يومك بمحادثة ممتعة ومثيرة!',
    '🚀 اجعل وقتك أكثر متعة مع دردشة الفيديو',
    '💫 أشخاص مميزون ينتظرون التحدث معك',
    '🎈 استكشف عالم جديد من المحادثات الشيقة',
  ];

  // أوقات الإشعارات (ساعة:دقيقة)
  static const List<Map<String, int>> _notificationTimes = [
    {'hour': 9, 'minute': 0},   // 9:00 صباحاً
    {'hour': 12, 'minute': 30}, // 12:30 ظهراً
    {'hour': 16, 'minute': 0},  // 4:00 عصراً
    {'hour': 19, 'minute': 30}, // 7:30 مساءً
    {'hour': 21, 'minute': 0},  // 9:00 مساءً
  ];

  // تهيئة الخدمة
  Future<void> initialize() async {
    if (kIsWeb) return; // تجاهل التهيئة على الويب

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestPermissions();
    } catch (e) {
      print('خطأ في تهيئة الإشعارات: $e');
    }
  }

  // معالج النقر على الإشعار
  static void _onNotificationTapped(NotificationResponse response) {
    print('تم النقر على الإشعار: ${response.payload}');
    // يمكن إضافة منطق للتنقل إلى شاشة معينة
  }

  // طلب أذونات الإشعارات
  Future<bool> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  // جدولة الإشعارات اليومية
  Future<void> scheduleDailyNotifications() async {
    if (kIsWeb) return;

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('لم يتم منح إذن الإشعارات');
      return;
    }

    // إلغاء جميع الإشعارات المجدولة سابقاً
    await cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!isEnabled) {
      print('الإشعارات معطلة من قبل المستخدم');
      return;
    }

    // جدولة إشعار لكل وقت محدد
    for (int i = 0; i < _notificationTimes.length; i++) {
      final time = _notificationTimes[i];
      await _scheduleDailyNotification(
        id: i,
        hour: time['hour']!,
        minute: time['minute']!,
      );
    }

    print('تم جدولة ${_notificationTimes.length} إشعار يومي');
  }

  // جدولة إشعار يومي واحد
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
  }) async {
    // اختيار رسالة عشوائية
    final random = Random();
    final message = _encouragementMessages[
    random.nextInt(_encouragementMessages.length)];

    // تحديد الوقت
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // إذا كان الوقت قد مر اليوم، جدول للغد
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // تحويل إلى timezone
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // تفاصيل الإشعار لـ Android
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'daily_reminders',
      'تذكيرات يومية',
      channelDescription: 'إشعارات تشجيعية للعودة للتطبيق',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      enableVibration: true,
      playSound: true,
    );

    // تفاصيل الإشعار لـ iOS
    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // جدولة الإشعار
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'دردشة فيديو عشوائية',
      message,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // تكرار يومي
      payload: 'daily_reminder_$id',
    );

    print('تم جدولة إشعار في $hour:$minute - $message');
  }

  // إرسال إشعار فوري للاختبار
  Future<void> sendTestNotification() async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'test_channel',
      'إشعارات اختبار',
      channelDescription: 'إشعارات للاختبار',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final random = Random();
    final message = _encouragementMessages[
    random.nextInt(_encouragementMessages.length)];

    await _flutterLocalNotificationsPlugin.show(
      999,
      'دردشة فيديو عشوائية',
      message,
      notificationDetails,
      payload: 'test_notification',
    );
  }

  // إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;

    await _flutterLocalNotificationsPlugin.cancelAll();
    print('تم إلغاء جميع الإشعارات');
  }

  // تفعيل/تعطيل الإشعارات
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      await scheduleDailyNotifications();
    } else {
      await cancelAllNotifications();
    }

    print('تم ${enabled ? "تفعيل" : "تعطيل"} الإشعارات');
  }

  // التحقق من حالة الإشعارات
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // الحصول على الإشعارات المجدولة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}