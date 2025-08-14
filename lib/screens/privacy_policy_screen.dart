import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(l10n.privacyPolicy),
                _buildLastUpdated(l10n.privacyPolicyLastUpdated),

                _buildParagraph(l10n.privacyPolicyIntro),

                _buildSectionTitle(l10n.privacyPolicySection1),
                _buildSubtitle(l10n.privacyPolicySection1_1),
                _buildBulletPoint(l10n.privacyPolicyRegistrationInfo),
                _buildBulletPoint(l10n.privacyPolicySharedContent),
                _buildBulletPoint(l10n.privacyPolicyReports),

                _buildSubtitle(l10n.privacyPolicySection1_2),
                _buildBulletPoint(l10n.privacyPolicyDeviceInfo),
                _buildBulletPoint(l10n.privacyPolicyUsageInfo),
                _buildBulletPoint(l10n.privacyPolicyNetworkInfo),

                _buildSectionTitle(l10n.privacyPolicySection2),
                _buildParagraph(l10n.privacyPolicySection2Intro),
                _buildBulletPoint(l10n.privacyPolicyProvideService),
                _buildBulletPoint(l10n.privacyPolicyImproveExperience),
                _buildBulletPoint(l10n.privacyPolicySendNotifications),
                _buildBulletPoint(l10n.privacyPolicyMaintainSecurity),
                _buildBulletPoint(l10n.privacyPolicyDetectViolations),
                _buildBulletPoint(l10n.privacyPolicyProvideSupport),

                _buildSectionTitle(l10n.privacyPolicySection3),
                _buildParagraph(l10n.privacyPolicySection3Intro),
                _buildBulletPoint(l10n.privacyPolicyShareWithUsers),
                _buildBulletPoint(l10n.privacyPolicyServiceProviders),
                _buildBulletPoint(l10n.privacyPolicyLegalRequirements),
                _buildBulletPoint(l10n.privacyPolicyProtectRights),

                _buildSectionTitle(l10n.privacyPolicySection4),
                _buildParagraph(l10n.privacyPolicyDataSecurity),

                _buildSectionTitle(l10n.privacyPolicySection5),
                _buildParagraph(l10n.privacyPolicyDataNotStored),

                _buildSectionTitle(l10n.privacyPolicySection6),
                _buildParagraph(l10n.privacyPolicyAdsThirdParty),

                _buildSectionTitle(l10n.privacyPolicySection7),
                _buildParagraph(l10n.privacyPolicyChildrenPrivacy),

                _buildSectionTitle(l10n.privacyPolicySection8),
                _buildParagraph(l10n.privacyPolicySection8Intro),
                _buildBulletPoint(l10n.privacyPolicyAccessCorrect),
                _buildBulletPoint(l10n.privacyPolicyDeleteInfo),
                _buildBulletPoint(l10n.privacyPolicyObjectProcessing),
                _buildBulletPoint(l10n.privacyPolicyRestrictProcessing),
                _buildBulletPoint(l10n.privacyPolicyDataPortability),
                _buildParagraph(l10n.privacyPolicyExerciseRights),

                _buildSectionTitle(l10n.privacyPolicySection9),
                _buildParagraph(l10n.privacyPolicyUpdates),

                _buildSectionTitle(l10n.privacyPolicySection10),
                _buildParagraph(l10n.privacyPolicyContactIntro),
                _buildParagraph(l10n.privacyPolicyContactEmail),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLastUpdated(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSubtitle(String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.black87,
        ),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}