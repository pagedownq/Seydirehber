import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/shimmer_widget.dart';
import '../../../core/services/local_cache_service.dart';
import '../../../core/services/haptic_service.dart';
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
                    HapticService.selection();
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
    // Ensure items are sorted by order and then guzergah
    final sortedItems = List<Map<String, dynamic>>.from(items);
    sortedItems.sort((a, b) {
      final aOrderVal = a['order'];
      final bOrderVal = b['order'];
      final num aOrder = num.tryParse(aOrderVal?.toString() ?? '') ?? 999999;
      final num bOrder = num.tryParse(bOrderVal?.toString() ?? '') ?? 999999;
      
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      
      final String aName = (a['guzergah'] ?? '').toString().toLowerCase();
      final String bName = (b['guzergah'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        return _BusScheduleItem(
          data: sortedItems[index],
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
    final oldSaatler = widget.data['saatler'] as String? ?? '';
    final hergun = widget.data['saatler_hergun'] as String? ?? '';
    final haftaici = widget.data['saatler_haftaici'] as String? ?? '';
    final cumartesi = widget.data['saatler_cumartesi'] as String? ?? '';
    final pazar = widget.data['saatler_pazar'] as String? ?? '';
    final duraklar = widget.data['duraklar'] as String?;

    // Parse times
    final now = DateTime.now();
    final currentTimeStr = DateFormat('HH:mm').format(now);
    final weekday = now.weekday; // 1: Mon, 7: Sun

    // Helper to merge and sort times
    List<String> getTimes(String specific) {
      final combined = "$oldSaatler|$hergun|$specific";
      return combined.split(RegExp(r'[,|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
          ..sort();
    }

    final haftaiciList = getTimes(haftaici);
    final cumartesiList = getTimes(cumartesi);
    final pazarList = getTimes(pazar);

    // Current day's list for next trip logic
    List<String> currentDayTimes = [];
    String currentDayLabel = '';
    if (weekday >= 1 && weekday <= 5) {
      currentDayTimes = haftaiciList;
      currentDayLabel = 'Hafta İçi';
    } else if (weekday == 6) {
      currentDayTimes = cumartesiList;
      currentDayLabel = 'Cumartesi';
    } else if (weekday == 7) {
      currentDayTimes = pazarList;
      currentDayLabel = 'Pazar';
    }

    // Find next trip
    String? nextTrip;
    for (var time in currentDayTimes) {
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
              HapticService.selection();
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
                              Text('Sıradaki ($currentDayLabel): ', style: AppTextStyles.bodySmall),
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
                            'Bugün bir sonraki sefer: $nextTrip',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _buildDaySection('Hafta İçi', haftaiciList, currentDayLabel == 'Hafta İçi', nextTrip, currentTimeStr),
                  _buildDaySection('Cumartesi', cumartesiList, currentDayLabel == 'Cumartesi', nextTrip, currentTimeStr),
                  _buildDaySection('Pazar', pazarList, currentDayLabel == 'Pazar', nextTrip, currentTimeStr),

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

  Widget _buildDaySection(String label, List<String> times, bool isCurrentDay, String? nextTrip, String currentTimeStr) {
    if (times.isEmpty) return const SizedBox.shrink();
    return _DayScheduleSection(
      label: label,
      times: times,
      isCurrentDay: isCurrentDay,
      nextTrip: nextTrip,
      currentTimeStr: currentTimeStr,
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

class _DayScheduleSection extends StatefulWidget {
  final String label;
  final List<String> times;
  final bool isCurrentDay;
  final String? nextTrip;
  final String currentTimeStr;

  const _DayScheduleSection({
    required this.label,
    required this.times,
    required this.isCurrentDay,
    this.nextTrip,
    required this.currentTimeStr,
  });

  @override
  State<_DayScheduleSection> createState() => _DayScheduleSectionState();
}

class _DayScheduleSectionState extends State<_DayScheduleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isCurrentDay;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            HapticService.selection();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: widget.isCurrentDay ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (widget.isCurrentDay) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Bugün', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: widget.isCurrentDay ? AppColors.primary : AppColors.textLight.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.times.map((saat) {
                final isNext = widget.isCurrentDay && saat == widget.nextTrip;
                final hasPassed = widget.isCurrentDay && saat.compareTo(widget.currentTimeStr) < 0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isNext
                        ? Colors.green
                        : (hasPassed ? Colors.grey.withOpacity(0.05) : Colors.grey.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isNext ? Colors.green : (widget.isCurrentDay ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                  child: Text(
                    saat,
                    style: TextStyle(
                      color: isNext ? Colors.white : (hasPassed ? Colors.grey : AppColors.textPrimary),
                      fontWeight: isNext || widget.isCurrentDay ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
