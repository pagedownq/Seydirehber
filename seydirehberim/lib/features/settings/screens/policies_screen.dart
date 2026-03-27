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
            content: '''
Seydi Rehber olarak verilerinizin güvenliği bizim önceliğimizdir. Uygulamamızı kullandığınızda toplanan veriler şunlardır:

1. Toplanan Veriler:
Google ile giriş yaptığınızda adınız, e-posta adresiniz ve profil fotoğrafınız Firebase üzerinden authorize edilir. Bu bilgiler size daha kişiselleştirilmiş bir deneyim sunmak için kullanılır.

2. Veri Kullanımı:
Toplanan veriler sadece uygulama içindeki hizmetlerin (destek mesajları, favoriler vb.) yönetimi için kullanılır. Üçüncü şahıslarla asla paylaşılmaz.

3. Güvenlik:
Verileriniz Firebase (Google) altyapısında güvenle saklanmaktadır. İstediğiniz zaman hesabınızı silebilirsiniz.
''',
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            context,
            icon: Icons.assignment_outlined,
            title: 'Kullanım Koşulları',
            content: '''
Seydi Rehber uygulamasını kullanarak aşağıdaki koşulları kabul etmiş sayılırsınız:

1. Hizmet Kapsamı:
Bu uygulama Seydişehir ilçesindeki etkinlikler, mekanlar ve hizmetler hakkında bilgi sunmak amacıyla geliştirilmiştir. Verilerin doğruluğu için azami gayret gösterilse de sorumluluk kullanıcıya aittir.

2. Kullanıcı Sorumluluğu:
Uygulama üzerinden gönderilen mesajların ve yorumların içeriğinden kullanıcı sorumludur. Topluluk kurallarına aykırı davranışlar hesabın askıya alınmasına neden olabilir.

3. Telif Hakları:
Uygulama içeriğindeki haberler, görseller ve tasarımlar Seydi Rehber'e aittir. İzinsiz kopyalanması veya ticari amaçlarla kullanılması yasaktır.
''',
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            context,
            icon: Icons.gavel_outlined,
            title: 'KVKK Aydınlatma Metni',
            content: '''
6698 sayılı Kişisel Verilerin Korunması Kanunu uyarınca:

Seydi Rehber, kişisel verilerinizi kanuna uygun olarak işlemektedir. Verileriniz, ilçemizdeki sosyal hayatı kolaylaştırmak ve destek taleplerinizi yanıtlamak amacıyla işlenmektedir.

Kullanıcılar olarak;
- Verilerinizin işlenip işlenmediğini öğrenme,
- Yanlış verilerin düzeltilmesini isteme,
- Verilerin silinmesini talep etme haklarına sahipsiniz.

Her türlü KVKK talebiniz için "Ayarlar > Yardım ve Destek" bölümünden bize ulaşabilirsiniz.
''',
          ),
        ],
      ),
    );
  }

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
