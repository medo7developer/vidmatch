import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/account_deletion_service.dart';
import '../services/ad_service.dart';
import '../widgets/terms_dialog.dart';
import '../services/user_cleanup_service.dart';
import 'account_deletion_screen.dart';
import 'registration_screen.dart';
import 'video_chat_screen.dart';
import 'settings_screen.dart';
import 'filter_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _cleanupUserData();
    _checkDeletionRequest();
  }

  Future<void> _checkDeletionRequest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userId != null) {
      final accountDeletionService = AccountDeletionService();
      final deletionRequest = await accountDeletionService.getActiveDeletionRequest(authProvider.userId!);

      if (deletionRequest != null && mounted) {
        // عرض إشعار للمستخدم بأن حسابه قيد الحذف
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حسابك مجدول للحذف في غضون ${deletionRequest.remainingHours} ساعة'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'إلغاء الحذف',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountDeletionScreen()),
                );
              },
            ),
          ),
        );
      }
    }
  }

  // تنظيف بيانات المستخدم عند فتح التطبيق
  Future<void> _cleanupUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userId != null) {
      final cleanupService = UserCleanupService();

      // تنظيف بيانات المستخدم الحالي
      await cleanupService.cleanupCurrentUser(authProvider.userId!);

      // تنظيف أي جلسات عالقة
      await cleanupService.cleanupUserSessions(authProvider.userId!);
    }

    setState(() {
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adService = Provider.of<AdService>(context, listen: false);
    // استخدام مكتبة الترجمة لاستخراج النصوص المترجمة
    final l10n = AppLocalizations.of(context)!;
    // الحصول على مزود اللغة
    final localeProvider = Provider.of<LocaleProvider>(context);

    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أيقونة التطبيق
                      Image.asset(
                        'assets/images/logo.png',
                        height: MediaQuery.of(context).size.height * .20,
                      ).animate().fade(duration: 800.ms).scale(delay: 300.ms),

                      const SizedBox(height: 20),

                      // عنوان التطبيق - استخدام المفتاح المترجم
                      Text(
                        l10n.appTitle,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fade(delay: 500.ms, duration: 800.ms),

                      const SizedBox(height: 10),

                      // وصف التطبيق - استخدام المفتاح المترجم
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          l10n.welcomeMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ).animate().fade(delay: 700.ms, duration: 800.ms),

                      const SizedBox(height: 30),

                      // معلومات المستخدم إذا كان مسجلاً
                      if (authProvider.isRegistered)
                        Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 10,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${l10n.welcome}، ${authProvider.userName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.public,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      // استخدام اسم البلد المترجم حسب المفاتيح الموجودة
                                      Text(
                                        _getLocalizedCountryName(
                                          l10n,
                                          authProvider.country,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        authProvider.gender == l10n.male
                                            ? Icons.male
                                            : Icons.female,
                                        color:
                                            authProvider.gender == l10n.male
                                                ? Colors.blue
                                                : Colors.pink,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        authProvider.gender,
                                        style: TextStyle(
                                          color:
                                              authProvider.gender == l10n.male
                                                  ? Colors.blue
                                                  : Colors.pink,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fade(delay: 800.ms, duration: 800.ms)
                            .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 30),

                      // زر بدء المحادثة
                      ElevatedButton(
                            onPressed: () async {
                              // التحقق من التسجيل أولاً
                              if (!authProvider.isRegistered) {
                                // الانتقال إلى شاشة التسجيل
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegistrationScreen(),
                                  ),
                                );
                              }
                              // بعد التسجيل، التحقق من الشروط والموافقات
                              else if (!authProvider.isAuthenticated) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const TermsDialog(),
                                );
                              } else {
                                // عرض إعلان فاصل ذكي قبل بدء المحادثة
                                await adService.showSmartInterstitialAd();

                                // الانتقال إلى شاشة الدردشة
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const VideoChatScreen(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  authProvider.isRegistered
                                      ? Icons.video_call_rounded
                                      : Icons.person_add_alt,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  authProvider.isRegistered
                                      ? l10n.startNewChat
                                      : l10n.registerNewUser,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fade(delay: 900.ms, duration: 800.ms)
                          .slideY(begin: 0.3, end: 0),

                      // زر الفلاتر (يظهر فقط إذا كان المستخدم مسجلاً)
                      if (authProvider.isRegistered)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FilterSettingsScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.filter_list,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                            ),
                            label: Text(
                              l10n.filterSettings,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ).animate().fade(delay: 1100.ms, duration: 800.ms),
                    ],
                  ),
                ),
              ),

              // إعلان شريطي في أسفل الشاشة الرئيسية
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: adService.getBannerAdWidget(),
              ),
              // زر الإعدادات
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  label: Text(
                    l10n.settings,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة للحصول على اسم البلد المترجم
  String _getLocalizedCountryName(AppLocalizations l10n, String countryCode) {
    // استخدام switch أو استخدام reflection للحصول على المفتاح المناسب
    switch (countryCode.toLowerCase()) {
      case 'egypt':
        return l10n.egypt;
      case 'saudi_arabia':
      case 'saudiarabia':
        return l10n.saudiArabia;
      case 'uae':
        return l10n.uae;
      case 'kuwait':
        return l10n.kuwait;
      case 'qatar':
        return l10n.qatar;
      case 'bahrain':
        return l10n.bahrain;
      case 'oman':
        return l10n.oman;
      case 'jordan':
        return l10n.jordan;
      case 'lebanon':
        return l10n.lebanon;
      case 'syria':
        return l10n.syria;
      case 'iraq':
        return l10n.iraq;
      case 'palestine':
        return l10n.palestine;
      case 'morocco':
        return l10n.morocco;
      case 'algeria':
        return l10n.algeria;
      case 'tunisia':
        return l10n.tunisia;
      case 'libya':
        return l10n.libya;
      case 'sudan':
        return l10n.sudan;
      case 'usa':
      case 'united_states':
        return l10n.usa;
      // يمكن إضافة المزيد من البلدان حسب الحاجة
      default:
        return countryCode; // إرجاع الرمز الأصلي إذا لم يتم العثور على ترجمة
    }
  }
}
