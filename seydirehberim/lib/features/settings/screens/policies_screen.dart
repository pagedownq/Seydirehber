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
Son Güncelleme: 29 Mart 2026

Seydi Rehber olarak, kullanıcılarımızın kişisel verilerinin güvenliği ve gizliliği en temel önceliğimizdir. Bu politika, hangi verileri ne amaçla topladığımızı ve nasıl koruduğumuzu açıklar.

1. Toplanan Veriler ve Kullanım Amaçları:
• Kimlik ve İletişim: Google ile giriş yapıldığında; ad, soyad ve e-posta adresi bilgileri Firebase altyapısı üzerinden alınır. Bu veriler sadece profilinizi oluşturmak, destek taleplerinizi yönetmek ve size özel içerikler sunmak için kullanılır.
• Konum Verileri: Uygulama içindeki mekanların (eczane, etkinlik vb.) size olan uzaklığını gösterebilmek için "Uygulamayı kullanırken" izniyle anlık konumunuz kullanılır. Bu veri sunucularımıza ASLA kaydedilmez ve üçüncü taraflarla paylaşılmaz.
• Cihaz ve Kullanım Bilgisi: Uygulama performansını artırmak ve hataları tespit etmek amacıyla anonim cihaz bilgileri (model, işletim sistemi) Google Analytics ve Crashlytics üzerinden işlenir.

2. Veri Güvenliği ve Paylaşımı:
• Verileriniz uçtan uca SSL/TLS şifreleme ile korunur.
• Verileriniz asla reklam ağlarına veya üçüncü şahıslara SATILMAZ.
• Veri işleme süreçleri sadece güvenli Google Cloud/Firebase altyapısı ile sınırlıdır.

3. Veri Saklama ve Silme:
• Kullanıcılar diledikleri zaman "Ayarlar > Hesabımı Sil" üzerinden veya seydirehber@gmail.com adresine yazarak tüm verilerinin kalıcı olarak silinmesini talep edebilirler. Talepler 7 gün içinde sonuçlandırılır.

4. Çerezler:
Uygulamamız oturum yönetimi ve analiz amaçlı güvenli dijital belirteçler (token) kullanmaktadır.
''';

  static const String termsOfServiceContent = '''
Son Güncelleme: 29 Mart 2026

Seydi Rehber uygulamasını kullanarak aşağıdaki şartları kabul etmiş sayılırsınız:

1. Hizmetin Doğası:
Bu uygulama, Seydişehir ilçesindeki sosyal hayatı kolaylaştırmak amacıyla bilgi sunan bir platformdur. Bilgilerin (saatler, konumlara ait veriler vb.) doğruluğu için azami gayret gösterilse de, kurumsal olmayan veya anlık değişen verilerdeki hatalardan Seydi Rehber sorumlu tutulamaz.

2. Kullanıcı Yükümlülükleri:
• Kullanıcılar, uygulama içinde yorum veya geri bildirim paylaşırken; küfür, hakaret, toplumu rahatsız edici öğeler veya yasa dışı içerikler paylaşmamayı taahhüt eder.
• Kural ihlali durumunda, ilgili içeriğin silinmesi ve kullanıcının erişiminin kalıcı olarak engellenmesi hakkı saklıdır.

3. Şikayet ve Denetim (UGC):
• Uygunsuz içerikler "Bildir" butonu veya destek hattı üzerinden raporlanabilir. Bildirilen içerikler 24 saat içinde moderatörlerimiz tarafından incelenir ve ihlal durumunda kalıcı olarak kaldırılır.

4. Sorumluluk Sınırı:
Seydi Rehber, hizmetin kesintisizliği veya üçüncü taraf harita servislerinden kaynaklanan aksaklıklardan sorumlu değildir.
''';

  static const String kvkkContent = '''
Son Güncelleme: 29 Mart 2026

6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) uyarınca Seydi Rehber, "Veri Sorumlusu" sıfatıyla aşağıdaki bilgilendirmeyi yapar:

1. Kişisel Verilerin İşlenme Amacı:
Kişisel verileriniz, uygulama hizmetlerinin sunulması, kullanıcı güvenliğinin sağlanması ve yasal yükümlülüklerin yerine getirilmesi amacıyla kanunlara uygun olarak işlenmektedir.

2. Haklarınız:
KVKK'nın 11. maddesi uyarınca;
• Verilerinizin işlenip işlenmediğini öğrenme,
• İşleme amacını öğrenme,
• Eksik veya yanlış verilerin düzeltilmesini isteme,
• Verilerin silinmesini veya yok edilmesini talep etme haklarına sahipsiniz.

3. Başvuru:
Veri sahibi olarak tüm taleplerinizi seydirehber@gmail.com adresine veya uygulama içindeki iletişim kanalları üzerinden bize iletebilirsiniz. Başvurularınız en geç 30 gün içinde yanıtlanacaktır.
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
