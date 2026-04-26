import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/haptic_service.dart';
import '../utils/map_helper.dart';

class MapButton extends StatelessWidget {
  final String locationUrl;
  final String label;

  const MapButton({
    super.key,
    required this.locationUrl,
    this.label = 'Harita Üzerinden Göster',
  });

  Future<void> _openMap() async {
    HapticService.vibrate();
    await MapHelper.openMapWithAddress(locationUrl);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openMap,
        icon: const Icon(Icons.map_outlined, size: 20),
        label: Text(label, style: AppTextStyles.button),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
