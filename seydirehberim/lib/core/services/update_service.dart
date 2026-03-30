import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  /// Android için uygulama içi güncelleme kontrolü yapar.
  /// Sadece release modda ve Android cihazlarda çalışır.
  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid || kDebugMode) {
      debugPrint('UpdateService: Güncelleme kontrolü atlanıyor (Platform: ${Platform.operatingSystem}, Debug: $kDebugMode)');
      return;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Eğer zorunlu (immediate) güncelleme izin veriliyorsa onu başlat
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } 
        // Yoksa esnek (flexible) güncelleme teklif et
        else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate().then((_) {
            // İndirme bittiğinde kullanıcıya yüklemesi için onay sorar (Play Store tarafından yönetilir)
            InAppUpdate.completeFlexibleUpdate();
          });
        }
      }
    } catch (e) {
      debugPrint('UpdateService Hatası: $e');
    }
  }
}
