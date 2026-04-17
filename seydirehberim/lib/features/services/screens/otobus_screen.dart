import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: dataAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerWidget.rectangular(height: 120, borderRadius: 20),
          ),
        ),
        error: (err, stack) {
          final cachedData = LocalCacheService.getList('otobus_saatleri');
          if (cachedData != null && cachedData.isNotEmpty) {
            return _buildBusList(cachedData, isFromManualCache: true);
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Veriler yüklenemedi'),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.refresh(otobusSaatleriProvider);
                  },
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        },
        data: (docs) {
          if (docs.isNotEmpty) {
            final dataList = docs.map((d) => d.data()).toList();
            LocalCacheService.saveList('otobus_saatleri', dataList);
          }

          if (docs.isEmpty) {
            final manualCache = LocalCacheService.getList('otobus_saatleri');
            if (manualCache != null && manualCache.isNotEmpty) {
              return _buildBusList(manualCache, isFromManualCache: true);
            }
            return const Center(child: Text('Henüz otobüs saati bulunmuyor.'));
          }

          final items = docs.map((d) => d.data()).toList();
          return _buildBusList(items);
        },
      ),
    );
  }

  Widget _buildBusList(List<Map<String, dynamic>> items, {bool isFromManualCache = false}) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
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
    final saatlerStr = widget.data['saatler'] as String? ?? '';
    final duraklar = widget.data['duraklar'] as String?;

    // Parse times
    final now = DateTime.now();
    final currentTimeStr = DateFormat('HH:mm').format(now);
    
    final allTimes = saatlerStr.split(RegExp(r'[,|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    
    // Sort times
    allTimes.sort((a, b) => a.compareTo(b));

    // Find next trip
    String? nextTrip;
    for (var time in allTimes) {
      if (time.compareTo(currentTimeStr) > 0) {
        nextTrip = time;
        break;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isExpanded ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isExpanded ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                   _buildBusIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guzergah, style: AppTextStyles.heading3.copyWith(fontSize: 18, height: 1.1)),
                        const SizedBox(height: 4),
                        if (nextTrip != null)
                          Row(
                            children: [
                              Text('Sıradaki: ', style: AppTextStyles.bodySmall),
                              Text(nextTrip, style: AppTextStyles.bodySmall.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          )
                        else
                          Text('Bugünkü seferler tamamlandı', style: AppTextStyles.bodySmall.copyWith(color: Colors.red.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textLight.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
          
          AnimatedCrossFade(
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 400),
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  
                  if (nextTrip != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active_outlined, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Bir sonraki sefer saati: $nextTrip',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text('Sefer Saatleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: allTimes.map((saat) {
                      final hasPassed = saat.compareTo(currentTimeStr) < 0;
                      final isNext = saat == nextTrip;
                      
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isNext 
                                  ? Colors.green 
                                  : (hasPassed ? Colors.grey.withOpacity(0.1) : AppColors.primarySurface),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isNext ? Colors.green : (hasPassed ? Colors.transparent : AppColors.primary.withOpacity(0.1)),
                              ),
                            ),
                            child: Text(
                              saat,
                              style: TextStyle(
                                color: isNext ? Colors.white : (hasPassed ? Colors.grey : AppColors.primary),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (hasPassed)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Geçti', style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 9)),
                            ),
                        ],
                      );
                    }).toList(),
                  ),

                  if (duraklar != null && duraklar.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.route_rounded, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Güzergah / Duraklar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Text(duraklar, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
    );
  }
}
