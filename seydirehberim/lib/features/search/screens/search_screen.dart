import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import 'package:go_router/go_router.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

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
            hintText: 'Ara...',
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).state = value,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textLight, size: 20),
              onPressed: () {
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
          ? const Center(child: Text('Aramak istediğiniz kelimeyi girin.'))
          : _SearchResultsList(query: query),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final String query;
  const _SearchResultsList({required this.query});

  @override
  Widget build(BuildContext context) {
    // We combine three streams to search across collections
    // For simplicity, we search for names starting with the query (case sensitive in Firestore unless normalized)
    // Note: Proper full-text search usually needs a separate service, but this is a starting point.
    
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
            onTap: () => context.push(s['route'] as String),
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
  }
}

class _SearchCollectionSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['ad'] ?? data['name'] ?? '').toString().toLowerCase();
          return name.contains(query);
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
                onTap: () => context.push('$routePrefix/${doc.id}'),
              );
            }),
            const Divider(),
          ],
        );
      },
    );
  }
}
