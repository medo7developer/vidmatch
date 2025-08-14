import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../screens/video_chat_screen.dart';
import '../screens/terms_of_service_screen.dart'; // أضف هذا
import '../screens/privacy_policy_screen.dart';   // أضف هذا

class TermsDialog extends StatefulWidget {
  const TermsDialog({Key? key}) : super(key: key);

  @override
  State<TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<TermsDialog> {
  bool _isAdult = false;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();

    // استرجاع القيم الحالية من AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      setState(() {
        _isAdult = authProvider.isAdult;
        _acceptTerms = authProvider.acceptedTerms;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        l10n.termsOfService,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'قبل استخدام تطبيق دردشة الفيديو العشوائية، يجب الموافقة على الشروط التالية:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // قائمة الشروط
            _buildTermItem(
              'يمنع منعاً باتاً مشاركة أي محتوى غير لائق أو مخالف للقانون.',
            ),
            _buildTermItem(
              'هذا التطبيق غير مخصص للأطفال تحت سن 18 عاماً.',
            ),
            _buildTermItem(
              'لا يتم تسجيل أو حفظ المحادثات بأي شكل من الأشكال.',
            ),
            _buildTermItem(
              'يجب الإبلاغ عن أي سلوك مسيء أو محتوى غير مناسب.',
            ),
            _buildTermItem(
              'نحتفظ بالحق في حظر أي مستخدم يخالف هذه الشروط.',
            ),

            const SizedBox(height: 20),

            // تأكيد العمر
            CheckboxListTile(
              value: _isAdult,
              onChanged: (value) {
                setState(() {
                  _isAdult = value ?? false;
                });
              },
              title: Text(
                l10n.confirmAdultAge,
                style: const TextStyle(fontSize: 14),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            // الموافقة على الشروط - مع روابط قابلة للضغط
            CheckboxListTile(
              value: _acceptTerms,
              onChanged: (value) {
                setState(() {
                  _acceptTerms = value ?? false;
                });
              },
              title: Wrap(
                children: [
                  const Text(
                    'أوافق على ',
                    style: TextStyle(fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'شروط الاستخدام',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    ' و ',
                    style: TextStyle(fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'سياسة الخصوصية',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: (_isAdult && _acceptTerms)
              ? () {
            // حفظ الإعدادات
            final authProvider = context.read<AuthProvider>();
            authProvider.confirmAdultAge(_isAdult);
            authProvider.acceptTerms(_acceptTerms);

            Navigator.of(context).pop();

            // الانتقال إلى شاشة الدردشة
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const VideoChatScreen(),
              ),
            );
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('موافق'),
        ),
      ],
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}