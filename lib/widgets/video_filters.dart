import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/webrtc_provider.dart';

class VideoFilters extends StatelessWidget {
  const VideoFilters({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final webrtcProvider = Provider.of<WebRTCProvider>(context);
    final activeFilter = webrtcProvider.activeFilter;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 70,
      color: Colors.black.withOpacity(0.5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        children: [
          _buildFilterOption(context, 'none', l10n.noFilter, activeFilter),
          _buildFilterOption(context, 'sepia', l10n.sepiaFilter, activeFilter),
          _buildFilterOption(context, 'grayscale', l10n.grayscaleFilter, activeFilter),
          _buildFilterOption(context, 'vintage', l10n.vintageFilter, activeFilter),
          _buildFilterOption(context, 'blur', l10n.blurFilter, activeFilter),
          _buildFilterOption(context, 'brightness', l10n.brightnessFilter, activeFilter),
          _buildFilterOption(context, 'contrast', l10n.contrastFilter, activeFilter),
          _buildFilterOption(context, 'hue', l10n.hueFilter, activeFilter),
        ],
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String filter, String label, String activeFilter) {
    final isActive = filter == activeFilter;

    return GestureDetector(
      onTap: () {
        final webrtcProvider = Provider.of<WebRTCProvider>(context, listen: false);
        webrtcProvider.applyVideoFilter(filter);
      },
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.black.withOpacity(0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForFilter(filter),
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Theme.of(context).colorScheme.primary : Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForFilter(String filter) {
    switch (filter) {
      case 'none':
        return Icons.filter_alt_off;
      case 'sepia':
        return Icons.filter_vintage;
      case 'grayscale':
        return Icons.monochrome_photos;
      case 'vintage':
        return Icons.photo_album;
      case 'blur':
        return Icons.blur_on;
      case 'brightness':
        return Icons.brightness_6;
      case 'contrast':
        return Icons.contrast;
      case 'hue':
        return Icons.color_lens;
      default:
        return Icons.filter;
    }
  }
}