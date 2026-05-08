import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
Son Güncelleme: 8 Mayıs 2026

Seydi Rehber olarak, kullanıcılarımızın kişisel verilerinin güvenliği ve gizliliği en temel önceliğimizdir. Uygulamamızı geliştirirken benimsediğimiz şeffaf veri kullanım ilkeleri aşağıdadır:

1. Toplanan Veriler ve Kullanım Amaçları:
• Kimlik Bilgileri: Giriş yapıldığında; ad, e-posta ve benzersiz kullanıcı kimliği (UID) bilgileriniz sadece size özel bir profil oluşturmak ve güvenliği sağlamak için kullanılır.
• Analiz ve Kullanım Verileri: Google Firebase Analytics altyapısını kullanarak; hangi sayfaların daha çok ziyaret edildiği, uygulama içi etkileşimler ve performans verileri toplanır. Bu veriler sadece uygulama kalitesini artırmak için kullanılır.
• Varlık (Presence) Takibi: Canlı istatistikler ve aktif kullanıcı sayısını belirleyebilmek için son görülme zamanı ve platform bilginiz (Android/iOS) sistemimizde tutulur.
• Konum Verileri: Harita ve uzaklık hesaplamaları için anlık konumunuz kullanılır. Konum verileriniz hiçbir şekilde sunucularımıza kaydedilmez.
• Bildirim Belirteçleri: Size duyurular yapabilmek için cihazınıza özel bildirim anahtarları (FCM Token) kullanılır.

2. Veri Güvenliği ve Üçüncü Taraflar:
Verileriniz hiçbir koşulda reklam ağlarına veya veri simsarlarına SATILMAZ. Tüm veriler dünya standartlarında güvenlik sağlayan Google Firebase altyapısında şifrelenmiş olarak korunur.

3. Veri Saklama ve Hesap Silme:
"Ayarlar > Hesabı Sil" adımlarını izleyerek tüm verilerinizi anında ve kalıcı olarak silebilirsiniz. Ayrıca web sitemiz üzerindeki iletişim formundan da verilerinizin silinmesini talep edebilirsiniz.
''';

  static const String termsOfServiceContent = '''
Son Güncelleme: 8 Mayıs 2026

Seydi Rehber uygulamasını kullanarak aşağıdaki kullanım koşullarını, topluluk standartlarını ve güvenlik şartlarını kabul etmiş sayılırsınız:

1. Temel Kullanım:
Uygulama tüm kullanıcılara açıktır. Misafir olarak gezinebilir veya daha gelişmiş özellikler için Google/Apple hesabınızla giriş yapabilirsiniz.

2. Topluluk ve İçerik (UGC) Kuralları:
Kullanıcılar tarafından oluşturulan tüm içerikler sıkı bir moderasyona tabidir. Platformumuzda güvenli bir ortam sağlamak için aşağıdaki eylemler kesinlikle yasaktır:
• Küfür, hakaret, argo, nefret söylemi veya tehdit içeren mesajlar paylaşmak.
• Yanıltıcı, yasa dışı, müstehcen veya telif hakkı ihlali içeren içerikler yayınlamak.
• Diğer kullanıcıları veya işletmeleri asılsız yere karalamak ve taciz etmek.

3. Moderasyon ve Denetim Sistemi:
• Raporlama (Şikayet): Uygunsuz içerikleri "Rapor Et" butonuyla bize bildirebilirsiniz. Moderatörlerimiz bildirimleri 24 saat içinde inceler ve ihlal varsa içeriği siler.
• Kullanıcı Engelleme: Sizi rahatsız eden kişileri "Engelle" özelliği ile anında akışınızdan gizleyebilirsiniz.
• Yaptırımlar: Kuralları ihlal eden hesaplar kalıcı olarak platformdan uzaklaştırılabilir.

4. Haber İçerikleri (RSS):
Haberler yerel basın kuruluşlarının RSS servislerinden derlenmektedir. Haberlerin yasal sorumluluğu asıl kaynak yayıncılara aittir. Uyar-Kaldır prensibi uygulanmaktadır.
''';

  static const String kvkkContent = '''
Son Güncelleme: 8 Mayıs 2026

6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) uyarınca Seydi Rehber, aşağıdaki hususları kullanıcılarına beyan eder:

1. Veri İşleme Amacı: 
Kişisel verileriniz; uygulama işlevselliğini sağlamak, kullanıcı güvenliğini korumak, kullanım istatistiklerini analiz ederek hizmet kalitesini artırmak amacıyla işlenmektedir.

2. Veri Güvenliği:
Verileriniz şifrelenmiş veritabanlarında saklanmakta ve üçüncü taraf reklam ağlarıyla paylaşılmamaktadır. Analitik veriler sadece uygulama performans ölçümü için kullanılır.

3. İlgili Kişinin Hakları: 
Kanun kapsamında; verilerinizin işlenip işlenmediğini öğrenme ve dilediğiniz an verilerinizin tamamen silinmesini isteme hakkına sahipsiniz. Uygulama içerisindeki "Hesabı Sil" seçeneği bu talebinizi anında yerine getirir.

4. İletişim: 
Gizlilik ile ilgili sorularınız için destek bölümünden veya seydirehber@gmail.com üzerinden bize ulaşabilirsiniz.
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
        onTap: () {
          _showPolicyDetail(context, title, content);
        },
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
