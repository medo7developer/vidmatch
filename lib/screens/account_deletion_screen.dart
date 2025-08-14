import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/account_deletion_service.dart';
import '../models/deletion_request_model.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({Key? key}) : super(key: key);

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final _accountDeletionService = AccountDeletionService();
  bool _isLoading = true;
  bool _confirmDelete = false;
  DeletionRequestModel? _activeDeletionRequest;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  // التحقق من وجود طلب حذف نشط
  Future<void> _checkExistingRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        _activeDeletionRequest = await _accountDeletionService.getActiveDeletionRequest(userId);
      }
    } catch (e) {
      print('خطأ في التحقق من طلب الحذف: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // طلب حذف الحساب
  Future<void> _requestAccountDeletion() async {
    if (!_confirmDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تأكيد رغبتك في حذف الحساب عن طريق تحديد مربع التأكيد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        _activeDeletionRequest = await _accountDeletionService.createDeletionRequest(userId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب حذف الحساب بنجاح. سيتم تنفيذ الحذف خلال 48 ساعة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // إلغاء طلب حذف الحساب
  Future<void> _cancelDeletionRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        await _accountDeletionService.cancelDeletionRequest(userId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء طلب حذف الحساب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        _activeDeletionRequest = null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حذف الحساب'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _activeDeletionRequest != null
            ? _buildActiveDeletionRequest()
            : _buildNewDeletionRequest(),
      ),
    );
  }

  // بناء واجهة عرض طلب الحذف النشط
  Widget _buildActiveDeletionRequest() {
    final remainingHours = _activeDeletionRequest!.remainingHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'طلب حذف الحساب نشط',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'سيتم حذف حسابك تلقائيًا بعد:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$remainingHours ساعة',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'بعد انتهاء المدة، سيتم حذف جميع بياناتك من التطبيق بشكل دائم ولا يمكن التراجع عن هذا الإجراء.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _cancelDeletionRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'إلغاء طلب حذف الحساب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'يمكنك إلغاء طلب حذف الحساب في أي وقت قبل انتهاء المدة المحددة.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // بناء واجهة طلب حذف جديد
  Widget _buildNewDeletionRequest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'حذف الحساب',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'تحذير: هذا الإجراء سيؤدي إلى حذف حسابك وجميع بياناتك بشكل دائم من التطبيق.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'عند طلب حذف الحساب، سيتم منحك فترة 48 ساعة للتراجع عن هذا القرار قبل حذف الحساب نهائيًا.\n\nبعد مرور 48 ساعة، سيتم حذف جميع بياناتك بما في ذلك:\n\n• معلومات الملف الشخصي\n• تاريخ الجلسات\n• الإعدادات والتفضيلات',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _confirmDelete,
          onChanged: (value) {
            setState(() {
              _confirmDelete = value ?? false;
            });
          },
          title: const Text(
            'أفهم أن هذا الإجراء لا يمكن التراجع عنه بعد انتهاء فترة 48 ساعة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          secondary: const Icon(Icons.check_circle, color: Colors.red),
          activeColor: Colors.red,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _requestAccountDeletion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'طلب حذف الحساب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'تراجع',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
