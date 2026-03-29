import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Politikalar', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPolicyItem(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            content: privacyPolicyContent,
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            context,
            icon: Icons.assignment_outlined,
            title: 'Kullanım Koşulları',
            content: termsOfServiceContent,
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            context,
            icon: Icons.gavel_outlined,
            title: 'KVKK Aydınlatma Metni',
            content: kvkkContent,
          ),
        ],
      ),
    );
  }

  static const String privacyPolicyContent = '''
Seydi Rehber olarak verilerinizin güvenliği ve gizliliği bizim için en önemli önceliktir. Google Play Veri Güvenliği politikalarıyla tam uyumlu hareket etmekteyiz.

1. Toplanan Veriler ve Amacı:
- Hesap Bilgileri: Google ile giriş yaptığınızda adınız, e-posta adresiniz ve profil fotoğrafınız Firebase (Google) üzerinden alınır. Bu bilgiler sadece kimliğinizi doğrulamak ve size özel bir deneyim sunmak (favoriler, destek talepleri vb.) için kullanılır.
- Cihaz Bilgileri: Uygulama performansı ve hata raporlarını takip etmek amacıyla anonim cihaz bilgileri (model, işletim sistemi sürümü) toplanabilir.
- Konum Verileri: Uygulamadaki mekanların size olan uzaklığını hesaplayabilmeniz için (izniniz dahilinde) konum bilgisi kullanılabilir. Bu veri asla sunucularımızda saklanmaz.

2. Veri Paylaşımı:
- Verileriniz asla üçüncü taraflara satılmaz veya ticari amaçlarla paylaşılmaz. Sadece uygulamanın çalışması için gerekli olan güvenli altyapı sağlayıcıları (Firebase/Google) ile sınırlıdır.

3. Veri Güvenliği:
- Tüm verileriniz endüstri standardı olan SSL/TLS şifreleme yöntemleri ile korunmaktadır. Veri tabanımız Google'ın yüksek güvenlikli sunucularında barındırılır.

4. Veri Silme Hakkı:
- Kullanıcılarımız diledikleri zaman tüm verilerinin silinmesini talep edebilirler.
- Hesabınızı uygulama içinden (Ayarlar > Hesabımı Sil) doğrudan silebilirsiniz.
- Ayrıca, seydirehber@gmail.com adresine e-posta göndererek verilerinizin tamamen silinmesini talep edebilirsiniz. Talebiniz 7 iş günü içerisinde yerine getirilecektir.
''';

  static const String termsOfServiceContent = '''
Seydi Rehber uygulamasını kullanarak aşağıdaki topluluk kurallarını ve kullanım şartlarını kabul etmiş sayılırsınız:

1. Hizmet Kapsamı:
Bu uygulama Seydişehir ilçesindeki sosyal hayatı zenginleştirmek için bilgi sunar. Sunulan bilgilerin doğruluğu için çalışılsa da, güncel durum değişikliklerinden kaynaklanan hatalardan kullanıcı sorumludur.

2. Kullanıcı Tarafından Oluşturulan İçerikler (UGC):
- Yorumlar ve Değerlendirmeler: Kullanıcıların yaptığı yorumlar tamamen kendilerine aittir.
- Yasaklı İçerikler: Küfür, hakaret, şiddet içerikli, yasa dışı veya toplumu rahatsız edici hiçbir içerik paylaşılamaz.
- Denetim: Uygulama yöneticileri, kuralları ihlal eden içerikleri önceden haber vermeksizin silme ve ilgili hesabın erişimini engelleme hakkına sahiptir.
- Şikayet Mekanizması: Uygunsuz bulduğunuz bir içeriği "Bildir" butonu veya destek bölümü aracılığıyla bize iletebilirsiniz. Şikayetler en geç 24 saat içinde incelenerek sonuçlandırılır.

3. Telif Hakları:
Uygulama tasarımı, logoları ve belirli içerikler Seydi Rehber'in fikri mülkiyetidir. İzinsiz kopyalanması kesinlikle yasaktır.
''';

  static const String kvkkContent = '''
6698 sayılı Kişisel Verilerin Korunması Kanunu uyarınca:

Seydi Rehber, kişisel verilerinizi kanuna uygun olarak işlemektedir. Verileriniz, ilçemizdeki sosyal hayatı kolaylaştırmak ve destek taleplerinizi yanıtlamak amacıyla işlenmektedir.

Kullanıcılar olarak;
- Verilerinizin işlenip işlenmediğini öğrenme,
- Yanlış verilerin düzeltilmesini isteme,
- Verilerin silinmesini talep etme haklarına sahipsiniz.

Her türlü KVKK talebiniz için "Ayarlar > Yardım ve Destek" bölümünden bize ulaşabilirsiniz.
''';

  Widget _buildPolicyItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        onTap: () => _showPolicyDetail(context, title, content),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showPolicyDetail(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: AppTextStyles.heading2)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
