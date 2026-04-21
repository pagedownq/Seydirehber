import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/haptic_service.dart';

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
    return IconButton(
      onPressed: () {
        HapticService.vibrate();
        Share.share(
          content,
          subject: subject,
        );
      },
      icon: const Icon(Icons.share_outlined),
      tooltip: 'Paylaş',
    );
  }
}
