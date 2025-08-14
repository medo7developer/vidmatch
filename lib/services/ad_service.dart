import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;

  AdService._internal();

  static AdService get instance => _instance;

  // معرفات الإعلانات (استخدم معرفات اختبار حتى الإنتاج)
  final String _bannerAdUnitId = kIsWeb
      ? '' // أو ممكن تسيبها فاضية عشان الويب مش مدعوم
      : (defaultTargetPlatform == TargetPlatform.android
      ? ' ca-app-pub-3096211653549421/7052438944'
      : ' ca-app-pub-3096211653549421/7052438944');

  final String _interstitialAdUnitId = kIsWeb
      ? ''
      : (defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-3096211653549421/3883318303'
      : 'ca-app-pub-3096211653549421/3883318303');

  final String _rewardedAdUnitId = kIsWeb
      ? ''
      : (defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-3096211653549421/3172903681'
      : 'ca-app-pub-3096211653549421/3172903681');

  // متغيرات حالة الإعلانات
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  // ترقيم لإنشاء إعلانات بانر فريدة
  int _bannerAdCounter = 0;

  // تخزين مؤقت للإعلانات البانر
  final Map<int, BannerAd> _bannerAdsCache = {};

  // متغيرات للتحكم الذكي في الإعلانات
  int _sessionCount = 0;
  int _interstitialShownCount = 0;
  DateTime? _lastInterstitialTime;

  // الحد الأدنى للوقت بين الإعلانات الفاصلة (بالثواني)
  final int _minTimeBetweenInterstitials = 180; // 3 دقائق

  // الحد الأقصى لعدد الإعلانات الفاصلة في اليوم
  final int _maxDailyInterstitials = 10;

  // دوال getter
  bool get isBannerAdReady => _bannerAd != null;
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;

  // تهيئة الإعلانات
  Future<void> initialize() async {
    if (kIsWeb) {
      print('AdService: الإعلانات غير مدعومة على الويب.');
      return;
    }

    await MobileAds.instance.initialize();
    await _loadAdStats();
    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // تحميل بيانات إحصائيات الإعلانات
  Future<void> _loadAdStats() async {
    final prefs = await SharedPreferences.getInstance();

    _sessionCount = prefs.getInt('ad_session_count') ?? 0;
    _interstitialShownCount = prefs.getInt('ad_interstitial_count') ?? 0;

    final lastInterstitialTimeMs = prefs.getInt('ad_last_interstitial_time');
    _lastInterstitialTime = lastInterstitialTimeMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastInterstitialTimeMs)
        : null;

    // إعادة ضبط عداد الإعلانات اليومي إذا كان آخر إعلان في يوم مختلف
    final now = DateTime.now();
    if (_lastInterstitialTime != null && _lastInterstitialTime!.day != now.day) {
      _interstitialShownCount = 0;
      await prefs.setInt('ad_interstitial_count', 0);
    }
  }

  // حفظ بيانات إحصائيات الإعلانات
  Future<void> _saveAdStats() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('ad_session_count', _sessionCount);
    await prefs.setInt('ad_interstitial_count', _interstitialShownCount);

    if (_lastInterstitialTime != null) {
      await prefs.setInt('ad_last_interstitial_time', _lastInterstitialTime!.millisecondsSinceEpoch);
    }
  }

  // تحميل إعلان شريطي
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('تم تحميل إعلان شريطي بنجاح');
        },
        onAdFailedToLoad: (ad, error) {
          print('فشل تحميل إعلان شريطي: $error');
          ad.dispose();
          _bannerAd = null;

          // إعادة المحاولة بعد فترة
          Future.delayed(const Duration(minutes: 1), _loadBannerAd);
        },
      ),
    );

    _bannerAd!.load();
  }

  // إنشاء إعلان شريطي جديد لكل استخدام
  BannerAd _createNewBannerAd() {
    final adId = _bannerAdCounter++;

    final bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('تم تحميل إعلان شريطي جديد بنجاح: $adId');
        },
        onAdFailedToLoad: (ad, error) {
          print('فشل تحميل إعلان شريطي جديد: $error');
          ad.dispose();
          _bannerAdsCache.remove(adId);
        },
        onAdClosed: (ad) {
          print('تم إغلاق الإعلان الشريطي: $adId');
          _bannerAdsCache.remove(adId);
          ad.dispose();
        },
      ),
    );

    _bannerAdsCache[adId] = bannerAd;
    bannerAd.load();

    return bannerAd;
  }

  // تحميل إعلان فاصل
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          // إعداد معالج الإغلاق
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isInterstitialAdReady = false;
              ad.dispose();
              _loadInterstitialAd(); // إعادة تحميل الإعلان للاستخدام التالي
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('فشل عرض الإعلان الفاصل: $error');
              _isInterstitialAdReady = false;
              ad.dispose();
              _loadInterstitialAd(); // إعادة المحاولة
            },
          );

          print('تم تحميل إعلان فاصل بنجاح');
        },
        onAdFailedToLoad: (error) {
          print('فشل تحميل إعلان فاصل: $error');
          _isInterstitialAdReady = false;

          // إعادة المحاولة بعد فترة
          Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
        },
      ),
    );
  }

  // تحميل إعلان مكافأة
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;

          // إعداد معالج الإغلاق
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isRewardedAdReady = false;
              ad.dispose();
              _loadRewardedAd(); // إعادة تحميل الإعلان للاستخدام التالي
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('فشل عرض إعلان المكافأة: $error');
              _isRewardedAdReady = false;
              ad.dispose();
              _loadRewardedAd(); // إعادة المحاولة
            },
          );

          print('تم تحميل إعلان مكافأة بنجاح');
        },
        onAdFailedToLoad: (error) {
          print('فشل تحميل إعلان مكافأة: $error');
          _isRewardedAdReady = false;

          // إعادة المحاولة بعد فترة
          Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
        },
      ),
    );
  }

  // عرض إعلان شريطي - صنع إعلان فريد لكل استخدام
  Widget getBannerAdWidget() {
    // إنشاء إعلان جديد في كل مرة
    final uniqueBannerAd = _createNewBannerAd();

    return Container(
      alignment: Alignment.center,
      width: uniqueBannerAd.size.width.toDouble(),
      height: uniqueBannerAd.size.height.toDouble(),
      child: AdWidget(ad: uniqueBannerAd),
    );
  }

  // التحقق من إمكانية عرض إعلان فاصل
  bool _canShowInterstitial() {
    final now = DateTime.now();

    // تحقق من عدم تجاوز الحد اليومي
    if (_interstitialShownCount >= _maxDailyInterstitials) {
      print('تم الوصول للحد الأقصى للإعلانات الفاصلة اليوم');
      return false;
    }

    // تحقق من مرور وقت كافٍ منذ آخر إعلان
    if (_lastInterstitialTime != null) {
      final secondsSinceLastAd = now.difference(_lastInterstitialTime!).inSeconds;
      if (secondsSinceLastAd < _minTimeBetweenInterstitials) {
        print('لم يمر وقت كافٍ منذ آخر إعلان فاصل');
        return false;
      }
    }

    // تحقق من منطق ذكي لعرض الإعلانات
    if (_sessionCount < 2) {
      // لا تعرض إعلانًا فاصلًا للمستخدمين الجدد جدًا
      return false;
    }

    return _isInterstitialAdReady;
  }

  // عرض إعلان فاصل ذكي
  Future<bool> showSmartInterstitialAd() async {
    // زيادة عداد الجلسات
    _sessionCount++;
    await _saveAdStats();

    if (!_canShowInterstitial()) return false;

    // تطبيق استراتيجية عرض ذكية
    // كلما زاد عدد الجلسات، زادت احتمالية عرض الإعلان
    final random = Random();
    final threshold = _calculateAdThreshold();

    if (random.nextDouble() < threshold) {
      if (_interstitialAd != null && _isInterstitialAdReady) {
        await _interstitialAd!.show();
        _interstitialShownCount++;
        _lastInterstitialTime = DateTime.now();
        await _saveAdStats();
        return true;
      }
    }

    return false;
  }

  // حساب عتبة الإعلان بناءً على سلوك المستخدم
  double _calculateAdThreshold() {
    // استراتيجية ذكية: كلما استخدم التطبيق أكثر، قلت احتمالية ظهور الإعلانات
    if (_sessionCount <= 5) {
      return 0.2;  // 20% فرصة للمستخدمين الجدد
    } else if (_sessionCount <= 20) {
      return 0.4;  // 40% فرصة للمستخدمين المتوسطين
    } else if (_sessionCount <= 50) {
      return 0.6;  // 60% فرصة للمستخدمين المنتظمين
    } else {
      return 0.3;  // تقليل الإعلانات للمستخدمين الأكثر ولاءً
    }
  }

  // عرض إعلان فاصل عند نهاية الجلسة
  Future<bool> showSessionEndAd() async {
    // تحقق من سياسة عرض الإعلانات عند نهاية الجلسة
    // نعرض إعلانًا فاصلاً بعد كل 2-3 جلسات
    if (_sessionCount % 3 == 0 && _canShowInterstitial()) {
      if (_interstitialAd != null && _isInterstitialAdReady) {
        await _interstitialAd!.show();
        _interstitialShownCount++;
        _lastInterstitialTime = DateTime.now();
        await _saveAdStats();
        return true;
      }
    }

    return false;
  }

  // عرض إعلان مكافأة واستلام مكافأة
  Future<bool> showRewardedAd({required Function onRewarded}) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.show(onUserEarnedReward: (_, reward) {
      onRewarded(reward.amount);
      completer.complete(true);
    });

    _isRewardedAdReady = false;
    _loadRewardedAd(); // إعادة تحميل للاستخدام التالي

    return completer.future;
  }

  // تسجيل جلسة جديدة
  Future<void> trackSession() async {
    _sessionCount++;
    await _saveAdStats();
  }

  // تنظيف الموارد
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();

    // تنظيف جميع إعلانات البانر المخزنة
    for (final ad in _bannerAdsCache.values) {
      ad.dispose();
    }
    _bannerAdsCache.clear();
  }
}