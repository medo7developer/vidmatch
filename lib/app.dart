import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'services/app_lifecycle_observer.dart';
import 'l10n/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RandomVideoChatApp extends StatefulWidget {
  const RandomVideoChatApp({Key? key}) : super(key: key);

  @override
  State<RandomVideoChatApp> createState() => _RandomVideoChatAppState();
}

class _RandomVideoChatAppState extends State<RandomVideoChatApp> {
  AppLifecycleObserver? _lifecycleObserver;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // تأجيل تهيئة المراقب حتى بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLifecycleObserver();
    });
  }

  void _initializeLifecycleObserver() {
    if (_isInitialized) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.userId != null) {
        _lifecycleObserver = AppLifecycleObserver(
          userId: authProvider.userId!,
          onAppPaused: () {
            print('تم وضع التطبيق في الخلفية');
          },
          onAppResumed: () {
            print('تم استئناف التطبيق');
          },
        );

        WidgetsBinding.instance.addObserver(_lifecycleObserver!);
        _isInitialized = true;
      }
    } catch (e) {
      print('خطأ في تهيئة مراقب دورة الحياة: $e');
    }
  }

  @override
  void dispose() {
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      _lifecycleObserver?.cleanupOnAppClose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'VidMatch',
          debugShowCheckedModeBanner: false,

          // إعدادات الترجمة
          locale: localeProvider.locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ضبط اتجاه التطبيق
          builder: (context, child) {
            return Directionality(
              textDirection: localeProvider.getTextDirection(),
              child: child!,
            );
          },

          // الثيم المحسن
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: ThemeMode.system,

          // الشاشة الرئيسية
          home: const SplashScreen(),

          // تحسين الأداء - تقليل عدد الإعدادات
          showPerformanceOverlay: false,
          showSemanticsDebugger: false,

          // إعدادات تحسين الأداء
          navigatorObservers: const [], // تقليل المراقبين
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    final textTheme = GoogleFonts.cairoTextTheme();

    return ThemeData(
      primarySwatch: Colors.blue,
      textTheme: textTheme,
      colorScheme: lightColorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // تحسين الأداء - تقليل الظلال والتأثيرات
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // تحسين الأداء - تقليل الأنيميشن
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final textTheme = GoogleFonts.cairoTextTheme();

    return ThemeData(
      primarySwatch: Colors.blue,
      textTheme: textTheme,
      colorScheme: darkColorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // تحسين الأداء - تقليل الأنيميشن
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}