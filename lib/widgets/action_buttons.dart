import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ActionButtons extends StatelessWidget {
  final bool isMicEnabled;
  final bool isCameraEnabled;
  final bool isConnected;
  final bool isLoading;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onNextUser;
  final VoidCallback onEndCall;

  const ActionButtons({
    Key? key,
    required this.isMicEnabled,
    required this.isCameraEnabled,
    required this.isConnected,
    required this.isLoading,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onNextUser,
    required this.onEndCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // أزرار التحكم الرئيسية
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر الميكروفون
              ActionButton(
                icon: isMicEnabled ? Icons.mic : Icons.mic_off,
                backgroundColor: isMicEnabled ? Colors.transparent : Colors.red,
                color: Colors.white,
                size: 60,
                onPressed: onToggleMic,
                label: localizations.microphone,
              ),

              const SizedBox(width: 16),

              // زر البدء/التالي
              ActionButton(
                icon: isConnected ? Icons.skip_next_rounded : Icons.play_arrow_rounded,
                backgroundColor: Theme.of(context).colorScheme.primary,
                color: Colors.white,
                size: 70,
                isLoading: isLoading,
                label: isConnected ? localizations.next : localizations.start,
                onPressed: isLoading ? null : () {
                  // منع الضغط المتكرر بسرعة
                  if (isLoading) return;

                  if (isConnected) {
                    onNextUser();
                  } else {
                    onNextUser(); // استخدام نفس الدالة للبدء والانتقال للتالي
                  }
                },
              ),

              const SizedBox(width: 16),

              // زر الكاميرا
              ActionButton(
                icon: isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                backgroundColor: isCameraEnabled ? Colors.transparent : Colors.red,
                color: Colors.white,
                size: 60,
                onPressed: onToggleCamera,
                label: localizations.camera,
              ),
            ],
          ),

          // زر إنهاء المكالمة
          if (isConnected)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ActionButton(
                icon: Icons.call_end,
                backgroundColor: Colors.red,
                color: Colors.white,
                size: 60,
                label: localizations.end,
                onPressed: onEndCall,
              ),
            ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double size;

  const ActionButton({
    Key? key,
    required this.icon,
    this.label,
    required this.color,
    this.backgroundColor,
    this.onPressed,
    this.isLoading = false,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
            boxShadow: backgroundColor != null && backgroundColor != Colors.transparent
                ? [
              BoxShadow(
                color: backgroundColor!.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isLoading ? null : onPressed,
              child: isLoading
                  ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
                  : Icon(
                icon,
                color: color,
                size: size * 0.5,
              ),
            ),
          ),
        ),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label!,
              style: TextStyle(
                color: isLoading ? Colors.grey : Colors.white,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}