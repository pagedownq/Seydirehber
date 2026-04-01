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
Son Güncelleme: 1 Nisan 2026

Seydi Rehber olarak, kullanıcılarımızın kişisel verilerinin güvenliği ve gizliliği en temel önceliğimizdir.

1. Toplanan Veriler ve Kullanım Amaçları:
• Kimlik Bilgileri: Google ile giriş yapıldığında; ad, soyad ve e-posta bilgileriniz profil oluşturmak ve destek talepleriniz için kullanılır.
• Konum Verileri: Mekanların uzaklığını göstermek için anlık konumunuz kullanılır. Sunucularımıza ASLA kaydedilmez.
• Kullanıcı Bildirimleri (Blok/Engel): Engellediğiniz kullanıcıların listesi sadece kendi cihazınızda (Shared Preferences) saklanır; bu veri sunucularımıza gönderilmez ve gizliliğiniz korunur.
• Cihaz Bilgisi: Performans ve hata analizi için anonim cihaz modelleri işlenir.

2. Veri Güvenliği ve Üçüncü Taraflar:
Verileriniz asla reklam ağlarına veya üçüncü şahıslara SATILMAZ. Sadece güvenli Firebase altyapısı üzerinde, şifrelenmiş olarak tutulur.

3. Veri Saklama ve Silme:
"Ayarlar > Hesabımı Sil" butonuyla tüm verilerinizi (yorumlar, profil) anında ve kalıcı olarak silebilirsiniz.
''';

  static const String termsOfServiceContent = '''
Son Güncelleme: 1 Nisan 2026

Seydi Rehber uygulamasını kullanarak aşağıdaki topluluk ve güvenlik şartlarını kabul etmiş sayılırsınız:

1. Yaş Kısıtlaması (18+):
Uygulama genel içerik sunsa da, "Yorum Yapma" ve "Değerlendirme" gibi sosyal etkileşim özellikleri sadece 18 yaşından büyük kullanıcılar içindir. Yorum yaparak bu şartı kabul etmiş sayılırsınız.

2. Kullanıcı Tarafından Oluşturulan İçerik (UGC) Kuralları:
Uygulama içinde paylaşılan tüm içerikler moderasyona tabidir. Aşağıdaki eylemler kesinlikle yasaktır:
• Küfür, hakaret, argo veya nefret söylemi kullanmak.
• Yanıltıcı, yasa dışı veya müstehcen içerik paylaşmak.
• Diğer kullanıcıları taciz etmek.

3. Moderasyon ve Denetim Sistemi:
• Raporlama: Uygunsuz bulduğunuz içerikleri "Rapor Et" butonuyla bildirebilirsiniz. Moderatörlerimiz bildirimleri 24 saat içinde inceler ve kural ihlali durumunda içeriği kalıcı olarak siler.
• Engelleme: "Kullanıcıyı Engelle" özelliği ile sizi rahatsız eden kişilerin içeriklerini anında ve kalıcı olarak gizleyebilirsiniz.
• Filtreleme: Sistemimiz otomatik küfür ve argo filtresi ile içerikleri denetlemektedir.

4. Yaptırımlar:
Kural ihlali yapan kullanıcıların yorumları silinir ve ihlalin tekrarı durumunda hesapları askıya alınabilir.
''';

  static const String kvkkContent = '''
Son Güncelleme: 1 Nisan 2026

6698 sayılı KVKK uyarınca Seydi Rehber, veri sorumlusu olarak aşağıdaki hususları beyan eder:

1. Veri İşleme: Verileriniz sadece hizmet sunumu, uygulama güvenliği ve topluluk kurallarının takibi amacıyla kanuna uygun işlenir.
2. Haklarınız: Verilerinizin işlenip işlenmediğini öğrenme, yanlış verileri düzeltme ve tüm verilerinizin (hesap silme yoluyla) yok edilmesini talep etme hakkına sahipsiniz.
3. İletişim: Tüm KVKK talepleriniz için seydirehber@gmail.com üzerinden bize ulaşabilirsiniz.
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
