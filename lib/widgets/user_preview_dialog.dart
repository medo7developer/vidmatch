import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserPreviewDialog extends StatelessWidget {
  final String userName;
  final String userCountry;
  final String userGender;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const UserPreviewDialog({
    Key? key,
    required this.userName,
    required this.userCountry,
    required this.userGender,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رمز المستخدم
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                userGender == 'ذكر' ? Icons.male : Icons.female,
                size: 40,
                color: userGender == 'ذكر' ? Colors.blue.shade300 : Colors.pink.shade300,
              ),
            )
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut),

            const SizedBox(height: 20),

            // عنوان
            Text(
              'تم العثور على مستخدم!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 800.ms),

            const SizedBox(height: 20),

            // معلومات المستخدم
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.person_outline,
                    'الاسم',
                    userName,
                    Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.public,
                    'البلد',
                    userCountry,
                    Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    userGender == 'ذكر' ? Icons.male : Icons.female,
                    'الجنس',
                    userGender,
                    userGender == 'ذكر' ? Colors.blue.shade300 : Colors.pink.shade300,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 25),

            // أزرار التحكم
            Row(
              children: [
                // زر الرفض
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.skip_next, size: 20),
                        const SizedBox(width: 6),
                        const Text('التالي', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // زر القبول
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_call, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'بدء المحادثة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 800.ms)
                .slideY(begin: 0.5, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
