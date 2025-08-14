import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randomvideochat/screens/privacy_policy_screen.dart';
import 'package:randomvideochat/screens/terms_of_service_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/app_state_manager.dart';
import '../widgets/report_dialog.dart';
import 'account_deletion_screen.dart';
import 'language_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // أضف هذه المتغيرات في _SettingsScreenState
  bool _notificationsEnabled = true;

  bool _isLoadingNotifications = false;

// أضف هذه الدالة في initState
  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

// إضافة دالة تحميل إعدادات الإشعارات
  Future<void> _loadNotificationSettings() async {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final isEnabled = await appStateManager.getNotificationStatus();

    setState(() {
      _notificationsEnabled = isEnabled;
    });
  }

// إضافة دالة تبديل الإشعارات
  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      await appStateManager.toggleNotifications(value);

      setState(() {
        _notificationsEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'تم تفعيل الإشعارات' : 'تم تعطيل الإشعارات'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('خطأ في تحديث إعدادات الإشعارات: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث إعدادات الإشعارات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

// إضافة دالة إرسال إشعار تجريبي
  Future<void> _sendTestNotification() async {
    try {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      await appStateManager.sendTestNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال إشعار تجريبي'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الإشعار التجريبي: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToOpenLink(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final currentUserId = authProvider.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // قسم الحساب
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.account,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(l10n.userId),
                  subtitle: Text(
                    authProvider.userId ?? l10n.notAvailable,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (authProvider.isRegistered)
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text(l10n.name),
                    subtitle: Text(
                      authProvider.userName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                if (authProvider.isRegistered)
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: Text(l10n.country),
                    subtitle: Text(
                      authProvider.country,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                SwitchListTile(
                  value: authProvider.isAdult,
                  onChanged: (value) {
                    authProvider.confirmAdultAge(value);
                  },
                  title: Text(l10n.confirmAdultAge),
                  subtitle: Text(l10n.appForAdultsOnly),
                  secondary: const Icon(Icons.verified_user),
                ),
                SwitchListTile(
                  value: authProvider.acceptedTerms,
                  onChanged: (value) {
                    authProvider.acceptTerms(value);
                  },
                  title: Text(l10n.acceptTermsAndConditions),
                  subtitle: Text(l10n.agreeToTermsAndPrivacy),
                  secondary: const Icon(Icons.assignment),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'الإشعارات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('تفعيل الإشعارات'),
            subtitle: const Text('إشعارات تشجيعية للعودة للتطبيق'),
            value: _notificationsEnabled,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: _isLoadingNotifications ? null : _toggleNotifications,
            secondary: _isLoadingNotifications
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(
              _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: _notificationsEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
          if (_notificationsEnabled)
            Column(
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('أوقات الإشعارات'),
                  subtitle: const Text('9:00 ص، 12:30 ظ، 4:00 م، 7:30 م، 9:00 م'),
                  trailing: const Icon(Icons.info_outline, size: 20),
                ),
                // const Divider(),
                // ListTile(
                //   leading: const Icon(Icons.send),
                //   title: const Text('إرسال إشعار تجريبي'),
                //   subtitle: const Text('لاختبار عمل الإشعارات'),
                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                //   onTap: _sendTestNotification,
                // ),
              ],
            ),

          const SizedBox(height: 16),

          // قسم اللغة والمظهر
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.displaySettings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  subtitle: Text(
                    localeProvider.getLanguageName(
                      localeProvider.locale.languageCode,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // قسم المعلومات القانونية
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.legalInformation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(l10n.privacyPolicy),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.gavel),
                  title: Text(l10n.termsOfService),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TermsOfServiceScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.warning_amber),
                  title: Text(l10n.reportAbuse),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final result = await ReportDialogHelper.showGeneralReport(
                      context: context,
                      reporterId: currentUserId!, // معرف المستخدم الحالي
                    );

                    if (result == true) {
                      // تم إرسال البلاغ بنجاح
                      print('Report submitted successfully');
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // قسم التطبيق
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.appInformation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(l10n.version),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: Text(l10n.rateApp),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // رابط متجر التطبيقات
                    _launchURL(
                      context,
                      'https://play.google.com/store/apps/details?id=com.winloop.vidmatch',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // قسم حذف الحساب
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'حذف الحساب',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('طلب حذف الحساب'),
                  subtitle: const Text(
                    'يمكنك طلب حذف حسابك وجميع بياناتك من التطبيق',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.red,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountDeletionScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // زر تسجيل الخروج
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                // تسجيل الخروج وإعادة ضبط الإعدادات
                authProvider.logout();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.settingsReset)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.resetSettings),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
