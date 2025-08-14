import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/webrtc_provider.dart';

class VideoRenderer extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final bool isLocal;

  const VideoRenderer({
    Key? key,
    required this.renderer,
    required this.isLocal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final webrtcProvider = Provider.of<WebRTCProvider>(context);
    final filter = isLocal && webrtcProvider.isFilterApplied
        ? webrtcProvider.activeFilter
        : 'none';
    final l10n = AppLocalizations.of(context)!;

    // التحقق من حالة المحرك وتوفر المحتوى
    bool hasContent = false;
    try {
      hasContent = renderer.srcObject != null;
    } catch (e) {
      print('خطأ في الوصول إلى srcObject للمحرك: $e');
    }

    return Container(
      color: Colors.black,
      child: hasContent
          ? Stack(
        children: [
          // تطبيق الفلتر حول RTCVideoView
          ClipRRect(
            child: ColorFiltered(
              colorFilter: _getFilterForName(filter),
              child: RTCVideoView(
                renderer,
                objectFit: isLocal
                    ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                    : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                mirror: isLocal,
              ),
            ),
          ),

          // عرض شارة للفلتر النشط
          if (isLocal && filter != 'none')
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _getFilterLocalizedName(filter, l10n),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  ColorFilter _getFilterForName(String filterName) {
    switch (filterName) {
      case 'sepia':
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'grayscale':
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'vintage':
        return const ColorFilter.matrix([
          0.9, 0.5, 0.1, 0, 0,
          0.3, 0.8, 0.1, 0, 0,
          0.2, 0.3, 0.5, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'blur':
      // لاحظ أن تأثير الضبابية لا يمكن إنشاؤه باستخدام ColorFilter فقط
      // سنستخدم لون مختلف لتمثيله في هذا المثال
        return const ColorFilter.mode(
          Colors.black12,
          BlendMode.saturation,
        );
      case 'brightness':
        return const ColorFilter.matrix([
          1.5, 0, 0, 0, 0,
          0, 1.5, 0, 0, 0,
          0, 0, 1.5, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'contrast':
        return const ColorFilter.matrix([
          2, 0, 0, 0, -0.5,
          0, 2, 0, 0, -0.5,
          0, 0, 2, 0, -0.5,
          0, 0, 0, 1, 0,
        ]);
      case 'hue':
        return const ColorFilter.matrix([
          0.213, 0.715, 0.072, 0, 0,
          0.213, 0.715, 0.072, 0, 0,
          0.213, 0.715, 0.072, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.mode(
          Colors.transparent,
          BlendMode.srcOver,
        );
    }
  }

  String _getFilterLocalizedName(String filter, AppLocalizations l10n) {
    switch (filter) {
      case 'sepia':
        return l10n.sepiaFilter;
      case 'grayscale':
        return l10n.grayscaleFilter;
      case 'vintage':
        return l10n.vintageFilter;
      case 'blur':
        return l10n.blurFilter;
      case 'brightness':
        return l10n.brightnessFilter;
      case 'contrast':
        return l10n.contrastFilter;
      case 'hue':
        return l10n.hueFilter;
      default:
        return l10n.noFilter;
    }
  }
}