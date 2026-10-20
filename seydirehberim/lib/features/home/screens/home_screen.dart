import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/haptic_service.dart';
import '../providers/home_providers.dart';
import '../widgets/banner_slider.dart';
import '../widgets/horizontal_card_list.dart';
import '../widgets/service_grid.dart';
import '../widgets/horizontal_coupon_list.dart';
import '../../../core/widgets/see_all_button.dart';
import '../../reports/providers/report_provider.dart';
import '../../reports/models/report_model.dart';
import '../../reports/widgets/add_report_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const HomeScreen({super.key, this.scrollController});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          // Basic AppBar
            SliverAppBar(
              backgroundColor: AppColors.white,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              title: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 22),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Seydi Rehber',
                      style: AppTextStyles.appBarTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    HapticService.selection();
                    context.push('/notifications');
                  },
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
              ],
            ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTopActionButton(
                      title: 'Hava Durumu',
                      icon: Icons.cloud_outlined,
                      gradient: AppColors.weatherGradient,
                      onTap: () {
                        context.push('/weather');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (buttonContext) => _buildTopActionButton(
                        title: 'Arkadaşlarınla Paylaş',
                        icon: Icons.share_outlined,
                        isBlack: true,
                        onTap: () {
                          // iOS/iPadOS için Share popup'ının nerede açılacağını belirtmemiz gerekiyor
                          final box = buttonContext.findRenderObject() as RenderBox?;
                          final rect = box != null 
                              ? box.localToGlobal(Offset.zero) & box.size 
                              : null;
                              
                          Share.share(
                            AppConstants.getShareText('Seydi Rehber uygulamasını indir ve Seydişehir hakkında her şeyi öğren! 📱'),
                            sharePositionOrigin: rect,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar (Static)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    context.push('/search');
                  },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: AppColors.textLight, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Etkinlik, firma, yer veya kategori ara...',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Banner Slider
          const SliverToBoxAdapter(
            child: BannerSlider(),
          ),

          /*
          // Real-time Alerts Section
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final reportsAsync = ref.watch(activeReportsProvider);
                final currentUser = ref.watch(authStateProvider).value;
                final isAdmin = ref.watch(isAdminProvider).value ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Anlık Durum Bildirimleri',
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final isGuest = ref.read(isGuestProvider);
                              if (isGuest) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bildirimde bulunmak için lütfen giriş yapın.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const AddReportSheet(),
                              );
                            },
                            icon: const Icon(Icons.add_alert, size: 16, color: Colors.white),
                            label: Text(
                              'Durum Bildir',
                              style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    reportsAsync.when(
                      loading: () => const SizedBox(
                        height: 130,
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ),
                      error: (err, stack) => const SizedBox(
                        height: 60,
                        child: Center(child: Text('Bildirimler yüklenemedi.')),
                      ),
                      data: (reports) {
                        if (reports.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Text('🌟', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Yollar Temiz!',
                                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Şu an aktif bildirilen bir yol çalışması veya kaza bulunmuyor.',
                                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: reports.length,
                            itemBuilder: (context, index) {
                              final report = reports[index];
                              final isConfirmed = currentUser != null && report.confirmedUserIds.contains(currentUser.uid);
                              final isUnconfirmed = currentUser != null && report.unconfirmedUserIds.contains(currentUser.uid);
                              final timeStr = DateFormat('HH:mm').format(report.dateTime);

                              return Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(report.reportCategory.emoji),
                                              const SizedBox(width: 4),
                                              Text(
                                                report.reportCategory.label,
                                                style: AppTextStyles.caption.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          timeStr,
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
                                        ),
                                        if (currentUser != null && (report.userId == currentUser.uid || isAdmin)) ...[
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () async {
                                              HapticService.selection();
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Bildirimi Sil'),
                                                  content: const Text('Bu anlık durum bildirimini silmek istediğinize emin misiniz?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Vazgeç'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                                      child: const Text('Sil'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                try {
                                                  await ref.read(reportOperationsProvider).deleteReport(report.id);
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Bildirim silindi.'),
                                                      backgroundColor: AppColors.success,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(e.toString()),
                                                      backgroundColor: AppColors.error,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Description & Address
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.description,
                                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 12, color: AppColors.textLight),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  report.address,
                                                  style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    // Verify Button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                report.confirmedUserIds.isEmpty
                                                    ? 'Henüz doğrulanmadı'
                                                    : '${report.confirmedUserIds.length} Doğrulama',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: report.confirmedUserIds.isEmpty
                                                      ? AppColors.textLight
                                                      : AppColors.success,
                                                  fontWeight: FontWeight.bold,
                                                  // ignore: deprecated_member_use
                                                ),
                                              ),
                                              if (report.unconfirmedUserIds.isNotEmpty)
                                                Text(
                                                  '${report.unconfirmedUserIds.length} Yanlış Bildirimi',
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: AppColors.error,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _VerifyButton(
                                              report: report,
                                              isConfirmed: isConfirmed,
                                              ref: ref,
                                            ),
                                            const SizedBox(width: 6),
                                            _UnverifyButton(
                                              report: report,
                                              isUnconfirmed: isUnconfirmed,
                                              ref: ref,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          */

          // Etkinlikler Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Etkinlikler',
                    onTap: () {
                      context.push('/events');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: latestEventsProvider,
                  type: CardType.event,
                  heroTagPrefix: 'latest-events',
                  onTap: (id) {

                    context.push('/events/$id');
                  },
                ),
              ],
            ),
          ),

          // Kuponlar Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Fırsat Kuponları',
                    onTap: () {
                      context.push('/coupons');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCouponList(
                  provider: latestCouponsProvider,
                  onTap: (id, data) {

                    context.push('/coupons/$id', extra: data);
                  },
                ),
              ],
            ),
          ),

          // Hizmetler Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Hizmetler', style: AppTextStyles.heading3),
                ),
                const SizedBox(height: 12),
                const RepaintBoundary(child: ServiceGrid()),
              ],
            ),
          ),

          // Gezilecek Yerler Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Gezilecek Yerler',
                    onTap: () => context.push('/places'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: allPlacesProvider,
                  type: CardType.place,
                  heroTagPrefix: 'latest-places',
                  onTap: (id) {

                    context.push('/places/$id');
                  },
                ),
              ],
            ),
          ),

          // Yeni Eklenen Firmalar Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Yeni Eklenen Firmalar',
                    onTap: () => context.push('/companies/latest'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: latestCompaniesProvider,
                  type: CardType.company,
                  heroTagPrefix: 'latest-companies',
                  onTap: (id) {
                    context.push('/companies/$id');
                  },
                ),
              ],
            ),
          ),

          // En Çok Ziyaret Edilen Firmalar Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'En Çok Ziyaret Edilen Firmalar',
                    onTap: () => context.push('/companies/popular'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: popularCompaniesProvider,
                  type: CardType.company,
                  heroTagPrefix: 'popular-companies',
                  onTap: (id) {
                    context.push('/companies/$id');
                  },
                ),
              ],
            ),
          ),

          // En Çok Değerlendirme Alan Firmalar Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'En Çok Değerlendirme Alan Firmalar',
                    onTap: () => context.push('/companies/rated'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: topRatedCompaniesProvider,
                  type: CardType.company,
                  heroTagPrefix: 'rated-companies',
                  showRating: true,
                  onTap: (id) {
                    context.push('/companies/$id');
                  },
                ),
              ],
            ),
          ),

          // Tüm Firmalar Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Tüm Firmalar',
                    onTap: () => context.push('/companies'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: allCompaniesProvider,
                  type: CardType.company,
                  heroTagPrefix: 'top-companies',
                  onTap: (id) {
                    context.push('/companies/$id');
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Gradient? gradient,
    bool isBlack = false,
  }) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isBlack ? Colors.black : (gradient == null ? Colors.white : null),
          gradient: isBlack ? null : gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isBlack ? Colors.black : (gradient?.colors.first ?? AppColors.primary))
                  .withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSearchField extends StatefulWidget {
  const _HomeSearchField();

  @override
  State<_HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<_HomeSearchField> {
  final TextEditingController _controller = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text.isNotEmpty != _showClear) {
        setState(() => _showClear = _controller.text.isNotEmpty);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {

          context.push('/search?q=${Uri.encodeComponent(value.trim())}');
        }
      },
      decoration: InputDecoration(
        hintText: 'Etkinlik, firma, yer veya kategori ara...',
        hintStyle: AppTextStyles.bodySmall,
        prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
        suffixIcon: _showClear
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  HapticService.selection();
                  _controller.clear();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _VerifyButton extends StatefulWidget {
  final TrafficReport report;
  final bool isConfirmed;
  final WidgetRef ref;

  const _VerifyButton({
    required this.report,
    required this.isConfirmed,
    required this.ref,
  });

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = widget.isConfirmed;
    return InkWell(
      onTap: _isLoading
          ? null
          : () async {
              final isGuest = widget.ref.read(isGuestProvider);
              if (isGuest) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doğrulamak için lütfen giriş yapın.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              HapticService.light();
              setState(() => _isLoading = true);
              try {
                await widget.ref
                    .read(reportOperationsProvider)
                    .toggleConfirmReport(widget.report.id);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isConfirmed ? AppColors.success : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (_isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(
                isConfirmed ? Icons.check_circle : Icons.check_circle_outline,
                size: 14,
                color: isConfirmed ? Colors.white : AppColors.textSecondary,
              ),
            const SizedBox(width: 4),
            Text(
              'Doğrula',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: isConfirmed ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnverifyButton extends StatefulWidget {
  final TrafficReport report;
  final bool isUnconfirmed;
  final WidgetRef ref;

  const _UnverifyButton({
    required this.report,
    required this.isUnconfirmed,
    required this.ref,
  });

  @override
  State<_UnverifyButton> createState() => _UnverifyButtonState();
}

class _UnverifyButtonState extends State<_UnverifyButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isUnconfirmed = widget.isUnconfirmed;
    return InkWell(
      onTap: _isLoading
          ? null
          : () async {
              final isGuest = widget.ref.read(isGuestProvider);
              if (isGuest) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doğrulamak için lütfen giriş yapın.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              HapticService.light();
              setState(() => _isLoading = true);
              try {
                await widget.ref
                    .read(reportOperationsProvider)
                    .toggleUnconfirmReport(widget.report.id);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isUnconfirmed ? AppColors.error : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (_isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.error,
                ),
              )
            else
              Icon(
                isUnconfirmed ? Icons.cancel : Icons.cancel_outlined,
                size: 14,
                color: isUnconfirmed ? Colors.white : AppColors.textSecondary,
              ),
            const SizedBox(width: 4),
            Text(
              'Yanlış',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnconfirmed ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
