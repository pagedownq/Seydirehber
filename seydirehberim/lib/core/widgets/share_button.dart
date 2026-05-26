import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/haptic_service.dart';
import '../constants/app_constants.dart';

class ShareButton extends StatelessWidget {
  final String content;
  final String? subject;

  const ShareButton({
    super.key,
    required this.content,
    this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => IconButton(
        onPressed: () {
          HapticService.vibrate();
          final box = buttonContext.findRenderObject() as RenderBox?;
          final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
          Share.share(
            AppConstants.getShareText(content),
            subject: subject,
            sharePositionOrigin: rect,
          );
        },
        icon: const Icon(Icons.share_outlined),
        tooltip: 'Paylaş',
      ),
    );
  }
}
