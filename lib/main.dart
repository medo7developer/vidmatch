import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:randomvideochat/services/account_deletion_service.dart';
import 'package:randomvideochat/services/app_state_manager.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/session_provider.dart';
import 'providers/webrtc_provider.dart';
import 'services/database_maintenance_service.dart';
import 'services/ad_service.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحسين إدارة الذاكرة
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
      print('خطأ Flutter: ${details.exception}');
    }
  };

  // تهيئة Firebase فقط مع timeout
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    print('خطأ في تهيئة Firebase: $e');
    // يمكن المتابعة حتى لو فشلت Firebase في بعض الحالات
  }

  // إنشاء مزودات الحالة الأساسية فقط
  final authProvider = AuthProvider();
  final localeProvider = LocaleProvider();

  // تحميل البيانات الأساسية فقط مع timeout
  try {
    await Future.wait([
      authProvider.generateUserId(),
      localeProvider.loadSavedLocale(),
    ]).timeout(const Duration(seconds: 5));
  } catch (e) {
    print('خطأ في تحميل البيانات الأساسية: $e');
    // المتابعة حتى لو فشل التحميل
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        // باقي المزودات - سيتم تحميلها عند الحاجة
        ChangeNotifierProvider<SessionProvider>(create: (_) => SessionProvider()),
        ChangeNotifierProvider<WebRTCProvider>(create: (_) => WebRTCProvider()),
        Provider<DatabaseMaintenanceService>(create: (_) => DatabaseMaintenanceService()),
        Provider<AdService>(create: (_) => AdService.instance),
        Provider<AccountDeletionService>(create: (_) => AccountDeletionService()),
        Provider<AppStateManager>(create: (_) => AppStateManager()),
      ],
      child: const RandomVideoChatApp(),
    ),
  );
}

// كلاس محسن لتهيئة الخدمات في الخلفية
class BackgroundServicesInitializer {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  static Future<void> initializeServices() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      // تهيئة الخدمات بشكل تدريجي مع timeout
      await _initializeServicesWithTimeout();
      _isInitialized = true;
    } catch (e) {
      print('خطأ في تهيئة الخدمات: $e');
    } finally {
      _isInitializing = false;
    }
  }

  static Future<void> _initializeServicesWithTimeout() async {
    // تهيئة الخدمات واحدة تلو الأخرى لتجنب التحميل الزائد

    // 1. تهيئة AppStateManager أولاً (أساسي)
    try {
      await _initializeAppStateManager().timeout(const Duration(seconds: 3));
    } catch (e) {
      print('خطأ في تهيئة AppStateManager: $e');
    }

    // 2. تهيئة الإعلانات (أقل أهمية)
    try {
      await _initializeMobileAds().timeout(const Duration(seconds: 5));
    } catch (e) {
      print('خطأ في تهيئة الإعلانات: $e');
    }

    // 3. تهيئة الصيانة (أقل أهمية)
    try {
      await _initializeMaintenanceService().timeout(const Duration(seconds: 3));
    } catch (e) {
      print('خطأ في تهيئة خدمة الصيانة: $e');
    }
  }

  static Future<void> _initializeMobileAds() async {
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      final adService = AdService.instance;
      await adService.initialize();
      await adService.trackSession();
    }
  }

  static Future<void> _initializeAppStateManager() async {
    final appStateManager = AppStateManager();
    await appStateManager.initialize();
  }

  static Future<void> _initializeMaintenanceService() async {
    final maintenanceService = DatabaseMaintenanceService();

    // فحص سريع للصيانة
    if (await maintenanceService.shouldPerformMaintenance()) {
      // تشغيل الصيانة في الخلفية دون انتظار
      maintenanceService.performMaintenanceNow();
    }

    maintenanceService.startPeriodicMaintenance(const Duration(hours: 6));
  }

  // دالة للتحقق من حالة الشبكة
  static Future<bool> _isNetworkAvailable() async {
    try {
      // محاولة بسيطة للتحقق من الاتصال
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}