import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../services/app_state_manager.dart';
import '../services/database_maintenance_service.dart';
import 'home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/webrtc_provider.dart';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isReady = false;
  String _loadingMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // مدة أقصر
    );
    _animationController.forward();

    // بدء التحميل السريع
    _quickInitialization();
  }

  Future<void> _quickInitialization() async {
    try {
      setState(() {
        _loadingMessage = 'جاري التحميل...';
      });

      // التحقق من الاتصال بالإنترنت أولاً
      final bool hasConnection = await _checkInternetConnection();

      if (!hasConnection) {
        setState(() {
          _loadingMessage = 'لا يوجد اتصال بالإنترنت - وضع عدم الاتصال';
        });

        // انتظار قصير ثم الانتقال
        await Future.delayed(const Duration(milliseconds: 1000));
        _navigateToHome();
        return;
      }

      // تحميل الخدمات الأساسية فقط
      await _loadEssentialServices();

      // تحميل الخدمات الإضافية في الخلفية
      _loadBackgroundServices();

      setState(() {
        _isReady = true;
        _loadingMessage = 'جاهز!';
      });

      // انتظار قصير للأنيميشن
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToHome();

    } catch (e) {
      print('خطأ في التحميل: $e');
      setState(() {
        _hasError = true;
        _loadingMessage = 'حدث خطأ - جاري المحاولة...';
      });

      // المحاولة مرة أخرى أو الانتقال للشاشة الرئيسية
      await Future.delayed(const Duration(milliseconds: 1000));
      _navigateToHome();
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadEssentialServices() async {
    try {
      // تحميل الخدمات الأساسية بسرعة
      await Future.wait([
        _initializeAppStateManager(),
        // لا نحمل WebRTC هنا - سيتم تحميله عند الحاجة
      ], eagerError: true).timeout(const Duration(seconds: 5));

    } catch (e) {
      print('خطأ في تحميل الخدمات الأساسية: $e');
      throw e;
    }
  }

  Future<void> _initializeAppStateManager() async {
    try {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      await appStateManager.initialize();
    } catch (e) {
      print('خطأ في AppStateManager: $e');
      // لا نتوقف هنا - يمكن المتابعة
    }
  }

  void _loadBackgroundServices() {
    // تحميل الخدمات في الخلفية دون انتظار
    BackgroundServicesInitializer.initializeServices().catchError((e) {
      print('خطأ في تحميل الخدمات في الخلفية: $e');
    });
  }

  void _navigateToHome() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
        settings: const RouteSettings(name: '/home'),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // لوجو التطبيق مع أنيميشن محسن
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.videocam,
                        size: 50,
                        color: Colors.white,
                      );
                    },
                  ),
                )
                    .animate(
                  controller: _animationController,
                )
                    .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                )
                    .fadeIn(duration: 300.ms),

                const SizedBox(height: 24),

                // اسم التطبيق
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate()
                    .fade(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut),

                const SizedBox(height: 6),

                // وصف التطبيق
                Text(
                  l10n.connectWithPeople,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                )
                    .animate()
                    .fade(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // مؤشر التحميل أو حالة الجاهزية
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildStatusWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (_isReady) {
      return Container(
        key: const ValueKey('ready'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'جاهز!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          .animate()
          .scale(
        begin: const Offset(0.8, 0.8),
        duration: 200.ms,
        curve: Curves.easeOutBack,
      )
          .fadeIn(duration: 150.ms);
    }

    return Column(
      key: const ValueKey('loading'),
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _loadingMessage,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 8),
          Text(
            'اضغط في أي مكان للمتابعة',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ],
    )
        .animate()
        .fade(delay: 300.ms, duration: 300.ms);
  }
}

// كلاس محسن لتحميل الخدمات في الخلفية
class BackgroundServicesInitializer {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  static Future<void> initializeServices() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      // تهيئة الخدمات بشكل تدريجي
      await _initializeServicesGradually();
      _isInitialized = true;
    } catch (e) {
      print('خطأ في تهيئة الخدمات في الخلفية: $e');
    } finally {
      _isInitializing = false;
    }
  }

  static Future<void> _initializeServicesGradually() async {
    // تأخير قصير لتجنب التحميل الفوري
    await Future.delayed(const Duration(milliseconds: 500));

    // تهيئة الخدمات واحدة تلو الأخرى
    final services = [
      _initializeMobileAds,
      _initializeMaintenanceService,
    ];

    for (final service in services) {
      try {
        await service().timeout(const Duration(seconds: 10));
        // تأخير قصير بين الخدمات
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('خطأ في تهيئة خدمة: $e');
        // المتابعة للخدمة التالية
      }
    }
  }

  static Future<void> _initializeMobileAds() async {
    if (!kIsWeb) {
      final adService = AdService.instance;
      await adService.initialize();
      await adService.trackSession();
    }
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
}