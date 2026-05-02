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
Son Güncelleme: 2 Mayıs 2026

Seydi Rehber olarak, kullanıcılarımızın kişisel verilerinin güvenliği ve gizliliği en temel önceliğimizdir. Bu doğrultuda uygulama içindeki veri kullanım ilkelerimiz aşağıda şeffaf bir şekilde açıklanmıştır:

1. Toplanan Veriler ve Kullanım Amaçları:
• Kimlik Bilgileri: Google veya Apple ile giriş yapıldığında; ad, soyad ve e-posta bilgileriniz sadece size özel bir profil oluşturmak ve destek taleplerinizde iletişime geçebilmek için kullanılır.
• Konum Verileri: Uygulama içi harita ve uzaklık hesaplamaları için anlık konumunuz kullanılır. Konum verileriniz hiçbir şekilde sunucularımıza kaydedilmez ve üçüncü şahıslarla paylaşılmaz.
• Cihaz ve Bildirim Bilgileri: Size zamanında hatırlatmalar ve duyurular yapabilmek için cihazınıza özel bildirim belirteçleri (Token) kullanılır. Bildirim tercihlerini istediğiniz zaman ayarlardan değiştirebilirsiniz.
• Kullanıcı Tercihleri: Engellediğiniz kullanıcıların veya favoriye aldığınız mekanların listesi uygulamanın güvenli altyapısında gizliliğiniz korunarak saklanır.

2. Veri Güvenliği ve Üçüncü Taraflar:
Verileriniz hiçbir koşulda reklam ağlarına, veri simsarlarına veya üçüncü şahıslara SATILMAZ. Tüm veriler dünya standartlarında güvenlik sağlayan Google Firebase altyapısı üzerinde, şifrelenmiş olarak tutulmaktadır.

3. Veri Saklama ve Silme:
Uygulama içindeki "Ayarlar > Hesabı Sil" adımlarını izleyerek profilinizi, yorumlarınızı ve tüm kişisel verilerinizi anında ve kalıcı olarak silebilirsiniz. Silinen verilerin geri dönüşü yoktur.
''';

  static const String termsOfServiceContent = '''
Son Güncelleme: 2 Mayıs 2026

Seydi Rehber uygulamasını kullanarak aşağıdaki kullanım koşullarını, topluluk standartlarını ve güvenlik şartlarını kabul etmiş sayılırsınız:

1. Temel Kullanım:
Uygulama tüm kullanıcılara açıktır ancak "Yorum Yapma", "Değerlendirme" ve "Destek Talebi Oluşturma" gibi etkileşimli özellikler için Google veya Apple hesabı ile giriş yapılması gereklidir.

2. Topluluk ve İçerik (UGC) Kuralları:
Kullanıcılar tarafından oluşturulan tüm içerikler sıkı bir moderasyona tabidir. Platformumuzda güvenli bir ortam sağlamak için aşağıdaki eylemler kesinlikle yasaktır:
• Küfür, hakaret, aşağılayıcı argo, nefret söylemi veya tehdit içeren mesajlar paylaşmak.
• Yanıltıcı, yasa dışı, müstehcen veya telif hakkı ihlali içeren içerikler yayınlamak.
• Diğer kullanıcıları veya işletmeleri asılsız yere karalamak ve taciz etmek.

3. Moderasyon ve Denetim Sistemi:
• Raporlama (Şikayet): Uygunsuz bulduğunuz içerikleri veya kullanıcıları "Rapor Et" butonuyla anında bize bildirebilirsiniz. Moderatörlerimiz bildirimleri en geç 24 saat içinde inceler ve kural ihlali tespit edilirse içeriği kalıcı olarak siler.
• Kullanıcı Engelleme: "Engelle" özelliği ile sizi rahatsız eden kişilerin içeriklerini anında akışınızdan gizleyebilir, bu kişilerle olan etkileşimi tamamen kapatabilirsiniz.
• Yaptırımlar: Topluluk kurallarını ihlal eden kullanıcıların içerikleri silinir. İhlalin boyutuna veya tekrarına bağlı olarak kullanıcı hesabı kalıcı olarak platformdan uzaklaştırılabilir.

4. Haber İçerikleri ve Telif Hakları (RSS):
Uygulamada yer alan "Haberler" bölümü, yerel basın kuruluşlarının halka açık RSS servislerinden otomatik olarak derlenmektedir. Haberlerin tüm mali ve manevi hakları, doğruluğu ve yasal sorumluluğu asıl kaynak yayıncılara aittir. "Uyar-Kaldır" prensibini benimsiyoruz; hak sahibi olduğunuz bir içeriğin kaldırılmasını talep ederseniz, ilgili içerik sistemimizden en kısa sürede çıkartılır.
''';

  static const String kvkkContent = '''
Son Güncelleme: 2 Mayıs 2026

6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) uyarınca Seydi Rehber, veri sorumlusu sıfatıyla aşağıdaki hususları kamuoyuna ve kullanıcılarına beyan eder:

1. Veri İşleme Amacı ve Hukuki Sebebi: 
Kişisel verileriniz (ad, soyad, e-posta vb.); yalnızca size daha iyi bir hizmet sunmak, kullanıcı hesap güvenliğini sağlamak, topluluk kurallarının takibini yapmak ve uygulamayı geliştirmek amacıyla kanuna uygun bir şekilde işlenmektedir.

2. İlgili Kişinin Hakları (Madde 11): 
Kanun kapsamında; kişisel verilerinizin işlenip işlenmediğini öğrenme, yanlış veya eksik verilerin düzeltilmesini talep etme ve verilerinizin tamamen yok edilmesini isteme hakkına sahipsiniz. Uygulama içerisindeki "Hesabı Sil" seçeneği bu hakkınızı otomatik ve anında yerine getirir.

3. İletişim: 
Her türlü yasal bildirim, KVKK talepleri ve veri gizliliği ile ilgili sorularınız için destek bölümünden veya doğrudan e-posta yoluyla bize ulaşabilirsiniz.
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
