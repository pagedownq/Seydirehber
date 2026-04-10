import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/shimmer_widget.dart';
import '../../../core/services/local_cache_service.dart';
import '../../home/providers/home_providers.dart';

class OtobusScreen extends ConsumerWidget {
  const OtobusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(otobusSaatleriProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Otobüs Saatleri', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      body: dataAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerWidget.rectangular(height: 100),
          ),
        ),
        error: (err, stack) {
          // Fallback to manual local cache on error
          final cachedData = LocalCacheService.getList('otobus_saatleri');
          if (cachedData != null && cachedData.isNotEmpty) {
            return _buildBusList(context, cachedData, isFromManualCache: true);
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Veriler yüklenemedi ve önbellek boş.'),
                TextButton(
                  onPressed: () => ref.refresh(otobusSaatleriProvider),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        },
        data: (docs) {
          // Save to manual local cache for extra redundancy
          if (docs.isNotEmpty) {
            final dataList = docs.map((d) => d.data()).toList();
            LocalCacheService.saveList('otobus_saatleri', dataList);
          }

          if (docs.isEmpty) {
            // If docs is empty, try our manual backup
            final manualCache = LocalCacheService.getList('otobus_saatleri');
            if (manualCache != null && manualCache.isNotEmpty) {
              return _buildBusList(context, manualCache, isFromManualCache: true);
            }
            return const Center(child: Text('Henüz otobüs saati eklenmemiş'));
          }

          final items = docs.map((d) => d.data()).toList();
          return _buildBusList(context, items);
        },
      ),
    );
  }

  Widget _buildBusList(BuildContext context, List<Map<String, dynamic>> items, {bool isFromManualCache = false}) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _BusScheduleItem(
          data: items[index],
          isFromManualCache: isFromManualCache,
        );
      },
    );
  }
}

class _BusScheduleItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isFromManualCache;

  const _BusScheduleItem({required this.data, required this.isFromManualCache});

  @override
  State<_BusScheduleItem> createState() => _BusScheduleItemState();
}

class _BusScheduleItemState extends State<_BusScheduleItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final guzergah = widget.data['guzergah'] as String? ?? '';
    final saatler = widget.data['saatler'] as String? ?? '';
    final duraklar = widget.data['duraklar'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_bus, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guzergah, style: AppTextStyles.heading3),
                        if (widget.isFromManualCache)
                          Text(
                            'Önbellekten Yüklendi',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          saatler, 
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (duraklar != null && duraklar.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.pin_drop_outlined, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            duraklar, 
                            style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
