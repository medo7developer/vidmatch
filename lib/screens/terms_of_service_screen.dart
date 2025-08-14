import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsOfService),
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
                _buildSectionTitle(l10n.termsOfService),
                _buildLastUpdated(l10n.termsOfServiceLastUpdated),

                _buildParagraph(l10n.termsOfServiceIntro),

                _buildSectionTitle(l10n.termsOfServiceSection1),
                _buildBulletPoint(l10n.termsOfServiceAdultOnly),
                _buildBulletPoint(l10n.termsOfServiceAccurateInfo),
                _buildBulletPoint(l10n.termsOfServiceAccountSecurity),
                _buildBulletPoint(l10n.termsOfServiceAccountResponsibility),

                _buildSectionTitle(l10n.termsOfServiceSection2),
                _buildParagraph(l10n.termsOfServiceSection2Intro),
                _buildBulletPoint(l10n.termsOfServiceNoInappropriate),
                _buildBulletPoint(l10n.termsOfServiceNoHarassment),
                _buildBulletPoint(l10n.termsOfServiceNoImpersonation),
                _buildBulletPoint(l10n.termsOfServiceNoDataCollection),
                _buildBulletPoint(l10n.termsOfServiceNoIllegalActivity),
                _buildBulletPoint(l10n.termsOfServiceNoAutomatedSoftware),
                _buildBulletPoint(l10n.termsOfServiceNoDisruption),
                _buildBulletPoint(l10n.termsOfServiceNoRecording),

                _buildSectionTitle(l10n.termsOfServiceSection3),
                _buildParagraph(l10n.termsOfServiceContentOwnership),
                _buildParagraph(l10n.termsOfServiceContentModeration),

                _buildSectionTitle(l10n.termsOfServiceSection4),
                _buildParagraph(l10n.termsOfServiceConversationPrivacy),
                _buildParagraph(l10n.termsOfServiceSensitiveInfo),

                _buildSectionTitle(l10n.termsOfServiceSection5),
                _buildParagraph(l10n.termsOfServiceReportAbusive),
                _buildParagraph(l10n.termsOfServiceEnforcementActions),

                _buildSectionTitle(l10n.termsOfServiceSection6),
                _buildParagraph(l10n.termsOfServiceAdvertisements),

                _buildSectionTitle(l10n.termsOfServiceSection7),
                _buildParagraph(l10n.termsOfServiceDisclaimer),
                _buildParagraph(l10n.termsOfServiceUserContentDisclaimer),

                _buildSectionTitle(l10n.termsOfServiceSection8),
                _buildParagraph(l10n.termsOfServiceLiabilityLimitation),

                _buildSectionTitle(l10n.termsOfServiceSection9),
                _buildParagraph(l10n.termsOfServiceIndemnification),

                _buildSectionTitle(l10n.termsOfServiceSection10),
                _buildParagraph(l10n.termsOfServiceModifications),

                _buildSectionTitle(l10n.termsOfServiceSection11),
                _buildParagraph(l10n.termsOfServiceGoverningLaw),

                _buildSectionTitle(l10n.termsOfServiceSection12),
                _buildParagraph(l10n.termsOfServiceContactIntro),
                _buildParagraph(l10n.termsOfServiceContactEmail),

                _buildSectionTitle(l10n.termsOfServiceSection13),
                _buildParagraph(l10n.termsOfServiceAcceptance),

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