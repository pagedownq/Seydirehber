import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/map_helper.dart';
import '../../home/providers/home_providers.dart';

class SeydiMapScreen extends ConsumerStatefulWidget {
  const SeydiMapScreen({super.key});

  @override
  ConsumerState<SeydiMapScreen> createState() => _SeydiMapScreenState();
}

class _SeydiMapScreenState extends ConsumerState<SeydiMapScreen> {
  String _selectedFilter = 'Tümü';
  final List<String> _filters = ['Tümü', 'Yerler', 'Firmalar', 'Etkinlikler', 'Noterler', 'Pazarlar'];
  
  final MapController _mapController = MapController();
  
  // Performance optimizations: Caching resolved coordinates and generated markers
  final Map<String, LatLng> _coordinateCache = {};
  final Map<String, Marker> _markerCache = {};
  final Set<String> _pendingResolutions = {};
  
  // Track previous filter to detect changes
  String _lastFilterUsed = '';

  // Seydişehir Center
  final LatLng _seydisehirCenter = const LatLng(37.418, 31.846);

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(allPlacesProvider);
    final companies = ref.watch(allCompaniesProvider);
    final events = ref.watch(allEventsProvider);
    final noterler = ref.watch(noterlerProvider);
    final pazarlar = ref.watch(pazarlarProvider);

    // Regenerate marker list only when needed
    // In a real high-performance app, we'd use a more reactive approach,
    // but for this dataset, simply caching the Marker objects themselves
    // and using sub-collection markers will be much faster.
    final markers = _generateMarkers(places, companies, events, noterler, pazarlar);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Seydi Harita', style: AppTextStyles.appBarTitle),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
            ),
            onPressed: () {
              _mapController.move(_seydisehirCenter, 14.5);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  _buildMap(markers),
                  _buildLoadingOverlay(places, companies, events, noterler, pazarlar),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = filter),
              borderRadius: BorderRadius.circular(25),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingOverlay(
    AsyncValue<FirestoreDocs> places,
    AsyncValue<FirestoreDocs> companies,
    AsyncValue<FirestoreDocs> events,
    AsyncValue<FirestoreDocs> noterler,
    AsyncValue<FirestoreDocs> pazarlar,
  ) {
    final isLoading = [places, companies, events, noterler, pazarlar].any((val) => val.isLoading);
    if (!isLoading) return const SizedBox.shrink();
    
    return Container(
      color: Colors.white.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
      ),
    );
  }

  Widget _buildMap(List<Marker> markers) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _seydisehirCenter,
        initialZoom: 14.5,
        maxZoom: 18.0,
        minZoom: 10.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Better perf without rotation
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.seydirehberim.app',
          tileProvider: CancellableNetworkTileProvider(),
          // Optimize tile loading
          tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 300)),
        ),
        MarkerLayer(
          markers: markers,
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }

  List<Marker> _generateMarkers(
    AsyncValue<FirestoreDocs> places,
    AsyncValue<FirestoreDocs> companies,
    AsyncValue<FirestoreDocs> events,
    AsyncValue<FirestoreDocs> noterler,
    AsyncValue<FirestoreDocs> pazarlar,
  ) {
    List<Marker> markers = [];

    // Filter detection
    if (_lastFilterUsed != _selectedFilter) {
      // We could clear some caches here if needed, but not necessary yet
      _lastFilterUsed = _selectedFilter;
    }

    if (_selectedFilter == 'Tümü' || _selectedFilter == 'Yerler') {
      markers.addAll(_getMarkersFromDocs(places, 'place', Colors.blue, '/places/'));
    }
    if (_selectedFilter == 'Tümü' || _selectedFilter == 'Firmalar') {
      markers.addAll(_getMarkersFromDocs(companies, 'company', Colors.green, '/companies/'));
    }
    if (_selectedFilter == 'Tümü' || _selectedFilter == 'Etkinlikler') {
      markers.addAll(_getMarkersFromDocs(events, 'event', Colors.purple, '/events/'));
    }
    if (_selectedFilter == 'Tümü' || _selectedFilter == 'Noterler') {
      markers.addAll(_getMarkersFromDocs(noterler, 'noter', Colors.red, '/noterler'));
    }
    if (_selectedFilter == 'Tümü' || _selectedFilter == 'Pazarlar') {
      markers.addAll(_getMarkersFromDocs(pazarlar, 'pazar', Colors.orange, '/pazarlar'));
    }

    return markers;
  }

  List<Marker> _getMarkersFromDocs(
    AsyncValue<FirestoreDocs> asyncDocs,
    String type,
    Color color,
    String routePrefix,
  ) {
    return asyncDocs.when(
      data: (docs) {
        List<Marker> markers = [];
        for (var doc in docs) {
          final data = doc.data();
          final String name = data['ad'] ?? (type == 'noter' ? 'Noter' : 'İsimsiz');
          final String? konum = data['konum'];
          
          if (konum != null && konum.isNotEmpty) {
            final docKey = '${doc.id}_$konum';
            
            // Check Marker Cache first (highest performance)
            if (_markerCache.containsKey(docKey)) {
              markers.add(_markerCache[docKey]!);
            } 
            // Then check Coordinate Cache and build marker if found
            else if (_coordinateCache.containsKey(docKey)) {
              final m = _buildMarker(doc.id, name, _coordinateCache[docKey]!, color, routePrefix, type);
              _markerCache[docKey] = m;
              markers.add(m);
            } 
            // Finally try quick parse or resolve async
            else {
              final coords = _quickParseCoords(konum);
              if (coords != null) {
                _coordinateCache[docKey] = coords;
                final m = _buildMarker(doc.id, name, coords, color, routePrefix, type);
                _markerCache[docKey] = m;
                markers.add(m);
              } else if (!_pendingResolutions.contains(docKey)) {
                _resolvePosition(docKey, konum);
              }
            }
          }
        }
        return markers;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  void _resolvePosition(String docKey, String locationData) async {
    _pendingResolutions.add(docKey);
    final coords = await MapHelper.getCoordinates(locationData);
    if (mounted && coords != null) {
      setState(() {
        _coordinateCache[docKey] = coords;
        _pendingResolutions.remove(docKey);
      });
    } else {
       _pendingResolutions.remove(docKey);
    }
  }

  LatLng? _quickParseCoords(String location) {
    if (!location.contains(',')) return null;
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    } catch (_) {}
    return null;
  }

  Marker _buildMarker(String id, String name, LatLng position, Color color, String routePrefix, String type) {
    // Simplified Marker Widget for better performance
    return Marker(
      point: position,
      width: 110,
      height: 60,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (type == 'noter' || type == 'pazar') {
             context.push(routePrefix);
          } else {
             context.push('$routePrefix$id');
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Using a simpler container without complex animations/shadows for base markers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.4), width: 1),
              ),
              child: Text(
                name.length > 15 ? '${name.substring(0, 12)}...' : name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.location_on, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'place': return Icons.park_outlined;
      case 'company': return Icons.storefront_outlined;
      case 'event': return Icons.celebration_outlined;
      case 'noter': return Icons.assignment_outlined;
      case 'pazar': return Icons.shopping_bag_outlined;
      default: return Icons.location_on_outlined;
    }
  }
}
