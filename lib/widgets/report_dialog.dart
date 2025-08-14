import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/report_service.dart';

class ReportDialog extends StatefulWidget {
  final String reporterId;
  final String? reportedUserId; // جعلها اختيارية للإبلاغ العام
  final String? reportedUserName; // جعلها اختيارية للإبلاغ العام
  final String? sessionId; // جعلها اختيارية للإبلاغ العام
  final bool isGeneralReport; // لتحديد نوع الإبلاغ

  const ReportDialog({
    Key? key,
    required this.reporterId,
    this.reportedUserId,
    this.reportedUserName,
    this.sessionId,
    this.isGeneralReport = false,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _reportService = ReportService();
  final _detailsController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_isSubmitting || _selectedReason == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.isGeneralReport) {
        // إبلاغ عام (بدون مستخدم محدد)
        await _reportService.submitGeneralReport(
          reporterId: widget.reporterId,
          reason: _selectedReason!,
          details: _detailsController.text.trim(),
        );
      } else {
        // إبلاغ عن مستخدم محدد
        await _reportService.submitReport(
          reporterId: widget.reporterId,
          reportedUserId: widget.reportedUserId!,
          reason: _selectedReason!,
          details: _detailsController.text.trim(),
          sessionId: widget.sessionId!,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        // إظهار رسالة نجاح
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reportSubmittedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error ?? 'خطأ'}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  List<String> _getReportReasons(AppLocalizations l10n) {
    if (widget.isGeneralReport) {
      // أسباب الإبلاغ العام
      return [
        l10n.technicalIssue ?? 'مشكلة تقنية',
        l10n.inappropriateContent ?? 'محتوى غير لائق',
        l10n.bugReport ?? 'بلاغ عن خطأ',
        l10n.featureRequest ?? 'طلب ميزة جديدة',
        l10n.accountIssue ?? 'مشكلة في الحساب',
        l10n.paymentIssue ?? 'مشكلة في الدفع',
        l10n.otherReason ?? 'سبب آخر',
      ];
    } else {
      // أسباب الإبلاغ عن مستخدم
      return [
        l10n.inappropriateContent ?? 'محتوى غير لائق',
        l10n.abusiveBehavior ?? 'سلوك مؤذي',
        l10n.harassment ?? 'مضايقة',
        l10n.violenceOrThreat ?? 'عنف أو تهديد',
        l10n.adultContent ?? 'محتوى للبالغين',
        l10n.impersonation ?? 'انتحال شخصية',
        l10n.otherReason ?? 'سبب آخر',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportReasons = _getReportReasons(l10n);

    // تهيئة السبب المحدد بأول عنصر من القائمة
    _selectedReason ??= reportReasons.first;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.report_problem, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isGeneralReport
                        ? (l10n.reportAbuse ?? 'الإبلاغ عن مخالفة')
                        : (l10n.reportingUser?.replaceAll('{}', widget.reportedUserName ?? '') ?? 'الإبلاغ عن المستخدم ${widget.reportedUserName ?? ''}'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              l10n.selectReportReason ?? 'اختر سبب الإبلاغ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedReason,
                  items: reportReasons.map((reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedReason = value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              l10n.additionalDetails ?? 'تفاصيل إضافية',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.additionalDetailsPlaceholder ?? 'اكتب تفاصيل إضافية هنا (اختياري)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel ?? 'إلغاء'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(l10n.submitReport ?? 'إرسال البلاغ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// دالة مساعدة لإظهار ديالوج الإبلاغ
class ReportDialogHelper {
  /// إظهار ديالوج الإبلاغ عن مستخدم محدد (للاستخدام في صفحة الدردشة)
  static Future<bool?> showUserReport({
    required BuildContext context,
    required String reporterId,
    required String reportedUserId,
    required String reportedUserName,
    String? sessionId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        sessionId: sessionId,
        isGeneralReport: false,
      ),
    );
  }

  /// إظهار ديالوج الإبلاغ العام (للاستخدام في القائمة العامة)
  static Future<bool?> showGeneralReport({
    required BuildContext context,
    required String reporterId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        reporterId: reporterId,
        isGeneralReport: true,
      ),
    );
  }
}