import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/app_info_provider.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../providers/search_history_provider.dart';
import '../../../core/widgets/shimmer_widget.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final debouncedSearchQueryProvider = StreamProvider.autoDispose<String>((ref) async* {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    yield '';
  } else {
    await Future.delayed(const Duration(milliseconds: 500));
    yield query;
  }
});

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    // Use addPostFrameCallback to update provider if initialQuery is present
    if (widget.initialQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchQueryProvider.notifier).state = widget.initialQuery!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: AppTextStyles.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Firma, yer veya kategori ara...',
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).state = value,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(searchHistoryProvider.notifier).addSearchTerm(value);
            }
          },
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textLight, size: 20),
              onPressed: () {
                HapticFeedback.selectionClick();
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Vazgeç',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: query.isEmpty
          ? _SearchHistoryList(
              onHistoryTap: (term) {
                HapticFeedback.selectionClick();
                _searchController.text = term;
                ref.read(searchQueryProvider.notifier).state = term;
              },
            )
          : const _SearchResultsList(),
    );
  }
}

class _SearchHistoryList extends ConsumerWidget {
  final Function(String) onHistoryTap;
  const _SearchHistoryList({required this.onHistoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);

    if (history.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_rounded,
        title: 'Neyi Aramıştın?',
        subtitle: 'Aramak istediğin kelimeyi yukarıdaki kutuya yazarak Seydişehir\'de keşfe çıkabilirsin.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Aramalar',
                style: AppTextStyles.heading3,
              ),
              TextButton(
                onPressed: () => ref.read(searchHistoryProvider.notifier).clearHistory(),
                child: const Text('Temizle', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: history.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final term = history[index];
              return ListTile(
                leading: const Icon(Icons.history, color: AppColors.textLight, size: 20),
                title: Text(term, style: AppTextStyles.bodyMedium),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
                  onPressed: () => ref.read(searchHistoryProvider.notifier).removeSearchTerm(term),
                ),
                onTap: () => onHistoryTap(term),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debouncedQueryAsync = ref.watch(debouncedSearchQueryProvider);
    final immediateQuery = ref.watch(searchQueryProvider);

    return debouncedQueryAsync.when(
      loading: () => const ShimmerSearchList(),
      error: (err, stack) => Center(child: Text('Arama sırasında hata oluştu: $err')),
      data: (query) {
        if (query.isEmpty && immediateQuery.isNotEmpty) {
          return const ShimmerSearchList();
        }
        
        if (query.isEmpty) return const SizedBox.shrink();

        final normalizedQuery = query.toLowerCase();
        
        // Static services/buttons that can be searched
        final services = [
          {'title': 'Hava Durumu', 'route': '/weather', 'icon': Icons.cloud_outlined},
          {'title': 'Nöbetçi Eczane', 'route': '/pharmacy', 'icon': Icons.local_pharmacy_outlined},
          {'title': 'Noterler', 'route': '/noterler', 'icon': Icons.gavel_rounded},
          {'title': 'Halk Pazarları', 'route': '/pazarlar', 'icon': Icons.storefront_rounded},
          {'title': 'Otobüs Saatleri', 'route': '/otobus', 'icon': Icons.directions_bus_rounded},
          {'title': 'Haberler', 'route': '/news', 'icon': Icons.newspaper_rounded},
        ];

        final filteredServices = services.where((s) => 
          (s['title'] as String).toLowerCase().contains(normalizedQuery)
        ).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (filteredServices.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Uygulama Özellikleri', style: AppTextStyles.heading3),
              ),
              ...filteredServices.map((s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s['icon'] as IconData, color: AppColors.primary),
                ),
                title: Text(s['title'] as String),
                subtitle: const Text('Uygulama içi kısayol'),
                onTap: () {
                  ref.read(searchHistoryProvider.notifier).addSearchTerm(normalizedQuery);
                  context.push(s['route'] as String);
                },
              )),
              const Divider(),
            ],
            _SearchCollectionSection(
              title: 'Etkinlikler',
              collection: 'etkinlikler',
              query: normalizedQuery,
              routePrefix: '/events',
            ),
            _SearchCollectionSection(
              title: 'Gezilecek Yerler',
              collection: 'yerler',
              query: normalizedQuery,
              routePrefix: '/places',
            ),
            _SearchCollectionSection(
              title: 'Firmalar',
              collection: 'firmalar',
              query: normalizedQuery,
              routePrefix: '/companies',
            ),
          ],
        );
      },
    );
  }
}

class _SearchCollectionSection extends ConsumerWidget {
  final String title;
  final String collection;
  final String query;
  final String routePrefix;

  const _SearchCollectionSection({
    required this.title,
    required this.collection,
    required this.query,
    required this.routePrefix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['ad'] ?? data['name'] ?? '').toString().toLowerCase();
          final category = (data['kategori'] ?? '').toString().toLowerCase();
          return name.contains(query) || category.contains(query);
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(title, style: AppTextStyles.heading3),
            ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['ad'] ?? data['name'] ?? '';
              final imageUrl = data['image_url'] ?? data['gorsel'] ?? '';
              final category = data['kategori'] as String? ?? '';
              
              final rawAdres = data['adres'] as String? ?? '';
              final rawKonum = data['konum'] as String? ?? '';
              final address = rawAdres.isNotEmpty ? rawAdres : (rawKonum.startsWith('http') ? '' : rawKonum);
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImageWidget(
                    imageUrl: imageUrl.toString(),
                    width: 50,
                    height: 50,
                    memCacheWidth: 100,
                    memCacheHeight: 100,
                    isCompany: routePrefix == '/companies',
                  ),
                ),
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty) 
                      Text(
                        category, 
                        style: TextStyle(
                          color: AppColors.primary, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w600
                        )
                      ),
                    if (address.isNotEmpty) 
                      Text(address, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                onTap: () {
                  ref.read(searchHistoryProvider.notifier).addSearchTerm(query);
                  context.push('$routePrefix/${doc.id}');
                },
              );
            }),
            const Divider(),
          ],
        );
      },
    );
  }
}
