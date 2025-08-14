import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LocaleProvider extends ChangeNotifier {
  // المفتاح المستخدم لتخزين اللغة المفضلة في الإعدادات المحلية
  static const String _localeKey = 'preferred_locale';
  static const String _isFirstLaunchKey = 'is_first_launch';

  // اللغة الافتراضية للتطبيق (ستتغير بناءً على لغة الجهاز)
  late Locale _locale;

  // قائمة اللغات المدعومة في التطبيق
  final List<Locale> supportedLocales = [
    const Locale('ar'), // العربية
    const Locale('en'), // الإنجليزية
    const Locale('fr'), // الفرنسية
    const Locale('hi'), // الهندية
    const Locale('de'), // الألمانية
  ];

  // الحصول على اللغة الحالية
  Locale get locale => _locale;

  // التحقق مما إذا كانت اللغة الحالية هي العربية
  bool get isArabic => _locale.languageCode == 'ar';

  // المزود يتم تهيئته مع اللغة العربية بشكل مؤقت حتى يتم تحميل الإعدادات
  LocaleProvider() {
    _locale = const Locale('ar'); // قيمة مؤقتة حتى تحميل اللغة الصحيحة
  }

  // تحميل اللغة المحفوظة من الإعدادات المحلية أو استخدام لغة الجهاز في المرة الأولى
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_isFirstLaunchKey) ?? true;

    if (isFirstLaunch) {
      // المرة الأولى لتشغيل التطبيق، استخدم لغة الجهاز
      await _setDeviceLocale(prefs);
    } else {
      // استخدم اللغة المحفوظة سابقاً
      final savedLocale = prefs.getString(_localeKey);
      if (savedLocale != null) {
        _locale = Locale(savedLocale);
      } else {
        // إذا لم تكن هناك لغة محفوظة (حالة نادرة)، استخدم لغة الجهاز
        await _setDeviceLocale(prefs);
      }
    }

    notifyListeners();
  }

  // استخراج لغة الجهاز وتعيينها كلغة افتراضية
  Future<void> _setDeviceLocale(SharedPreferences prefs) async {
    // الحصول على لغة الجهاز
    final deviceLocale = ui.window.locale;
    final deviceLanguage = deviceLocale.languageCode;

    // التحقق مما إذا كانت لغة الجهاز مدعومة في التطبيق
    final isSupported = supportedLocales.any(
            (locale) => locale.languageCode == deviceLanguage
    );

    // تعيين اللغة الافتراضية استنادًا إلى لغة الجهاز، أو العربية إذا لم تكن مدعومة
    if (isSupported) {
      _locale = Locale(deviceLanguage);
    } else {
      _locale = const Locale('en'); // استخدم الانجليزية كلغة احتياطية
    }

    // حفظ اللغة وتعليم أن التطبيق تم تشغيله من قبل
    await prefs.setString(_localeKey, _locale.languageCode);
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  // تغيير اللغة وحفظها في الإعدادات المحلية
  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLocales.contains(newLocale)) return;

    _locale = newLocale;

    // حفظ اللغة الجديدة
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);

    // إخطار المستمعين بالتغيير
    notifyListeners();
  }

  // استعادة لغة الجهاز وتعيينها كلغة افتراضية
  Future<void> resetToDeviceLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await _setDeviceLocale(prefs);
    notifyListeners();
  }

  // الحصول على اسم اللغة بناءً على رمز اللغة
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'hi':
        return 'हिंदी';
      case 'de':
        return 'Deutsch';
      default:
        return 'Unknown';
    }
  }

  // الحصول على كود اتجاه النص بناءً على اللغة الحالية
  TextDirection getTextDirection() {
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }
}