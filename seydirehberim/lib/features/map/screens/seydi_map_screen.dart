import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/map_helper.dart';
import '../../home/providers/home_providers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import '../../../core/services/log_service.dart';
import 'dart:async';

class SeydiMapScreen extends ConsumerStatefulWidget {
  const SeydiMapScreen({super.key});

  @override
  ConsumerState<SeydiMapScreen> createState() => _SeydiMapScreenState();
}

class _SeydiMapScreenState extends ConsumerState<SeydiMapScreen> {
  String _selectedFilter = 'Tümü';
  final List<String> _filters = ['Tümü', 'Yerler', 'Firmalar', 'Etkinlikler', 'Noterler', 'Pazarlar'];
  
  final Map<String, IconData> _filterIcons = {
    'Tümü': Icons.explore_rounded,
    'Yerler': Icons.park_rounded,
    'Firmalar': Icons.business_rounded,
    'Etkinlikler': Icons.celebration_rounded,
    'Noterler': Icons.gavel_rounded,
    'Pazarlar': Icons.shopping_basket_rounded,
  };
  
  final MapController _mapController = MapController();
  
  // Performance optimizations: Caching resolved coordinates and generated markers
  final Map<String, LatLng> _coordinateCache = {};
  final Map<String, Marker> _markerCache = {};
  final Set<String> _pendingResolutions = {};
  Timer? _rebuildTimer;
  
  // Track previous filter to detect changes
  String _lastFilterUsed = '';

  // New States for Map Features
  String _currentMapTheme = 'light';
  bool _showRadius = false;
  final double _radiusKm = 0.5;
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // User Location
  LatLng? _userLocation;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  // Seydişehir Center
  final LatLng _seydisehirCenter = const LatLng(37.418, 31.846);

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();

    // Listen for service status changes (e.g. user turns on GPS from notification tray)
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.enabled) {
        _checkPermissionAndGetLocation();
      }
    });
  }

  @override
  void dispose() {
    _rebuildTimer?.cancel();
    _locationSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cihazın konum servisi açık mı? (GPS anahtarı)
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LogService().info('Location service status: $serviceEnabled');
    
    if (!serviceEnabled) {
      if (mounted) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Android'de Google Play Servisleri diyaloğunu tetikle
          final location = loc.Location();
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) return;
        } else {
          _showLocationServiceDialog();
          return;
        }
      }
    }

    // 2. Uygulama izin durumunu kontrol et
    var status = await Permission.location.status;
    LogService().info('Location permission status: $status');

    if (status.isDenied) {
      LogService().info('Requesting location permission...');
      status = await Permission.location.request();
      LogService().info('Location permission request result: $status');
      
      if (status.isDenied) {
        // Kullanıcı reddetti
        return;
      }
    }

    if (status.isPermanentlyDenied) {
      LogService().warning('Location permissions are permanently denied.');
      if (mounted) _showPermissionDeniedDialog();
      return;
    }

    // 3. İzinler alındı, konumu al ve takibi başlat
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      LogService().error('Error getting initial position: $e');
    }

    if (_locationSubscription == null) {
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
            });
          }
        },
        onError: (e) => LogService().error('Location stream error: $e'),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded, size: 32, color: AppColors.error),
              ),
              const SizedBox(height: 24),
              Text(
                'Konum İzni Gerekli',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 12),
              const Text(
                'Uygulama özelliklerini tam kullanabilmek için konum iznine ihtiyacımız var. Lütfen uygulama ayarlarından izin verin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticService.selection();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.vibrate();
                        Navigator.pop(ctx);
                        openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ayarları Aç', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, size: 32, color: AppColors.warning),
              ),
              const SizedBox(height: 24),
              const Text(
                'Konum Servisi Kapalı',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cihazınızın konum servisi (GPS) kapalı. Lütfen Ayarlar > Gizlilik ve Güvenlik > Konum Servisleri adımlarını izleyerek aktif hale getirin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.vibrate();
                    Navigator.pop(ctx);
                    Geolocator.openLocationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ayarları Aç', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Vazgeç', style: TextStyle(color: AppColors.textLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              HapticService.vibrate();
              if (_userLocation != null) {
                _mapController.move(_userLocation!, 15.0);
              } else {
                _mapController.move(_seydisehirCenter, 14.5);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Map fills the whole area
          Positioned.fill(
            child: RepaintBoundary(
              child: _buildMap(markers),
            ),
          ),
          
          // Floating Search & Filter Bar at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildFilterBar(),
              ],
            ),
          ),
          
          // Compact loading indicator
          Positioned(
            top: 120, // Adjusted to not overlap with search & filter bar
            right: 20,
            child: _buildCompactLoadingIndicator(places, companies, events, noterler, pazarlar),
          ),
          
          // Map Controls (Theme & Radius)
          Positioned(
            bottom: 30,
            right: 16,
            child: _buildMapControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoadingIndicator(
    AsyncValue<FirestoreDocs> places,
    AsyncValue<FirestoreDocs> companies,
    AsyncValue<FirestoreDocs> events,
    AsyncValue<FirestoreDocs> noterler,
    AsyncValue<FirestoreDocs> pazarlar,
  ) {
    final isLoading = [places, companies, events, noterler, pazarlar].any((val) => val.isLoading);
    if (!isLoading) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
        ],
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          final icon = _filterIcons[filter] ?? Icons.category_rounded;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                if (_selectedFilter != filter) {
                  HapticService.selection();
                  setState(() => _selectedFilter = filter);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  String _getTileUrl() {
    switch (_currentMapTheme) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'light':
      default:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png';
    }
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
          urlTemplate: _getTileUrl(),
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.seydirehberim.app',
          tileProvider: CancellableNetworkTileProvider(),
          // Optimize tile loading performance
          tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 100)),
          keepBuffer: 5,
          panBuffer: 2,
        ),
        if (_showRadius && _userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _userLocation!,
                color: AppColors.primary.withOpacity(0.1),
                borderStrokeWidth: 2,
                borderColor: AppColors.primary.withOpacity(0.5),
                useRadiusInMeter: true,
                radius: _radiusKm * 1000,
              ),
            ],
          ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(40, 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(50),
            maxZoom: 15,
            markers: markers,
            builder: (context, clusterMarkers) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                  ],
                ),
                child: Center(
                  child: Text(
                    clusterMarkers.length.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, spreadRadius: 2)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            alignment: Alignment.topCenter,
          ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Radius Toggle Button
        FloatingActionButton.extended(
          heroTag: 'btnRadius',
          backgroundColor: _showRadius ? AppColors.primary : Colors.white,
          foregroundColor: _showRadius ? Colors.white : AppColors.primary,
          onPressed: () {
            HapticService.selection();
            setState(() {
              _showRadius = !_showRadius;
            });
          },
          icon: const Icon(Icons.radar_rounded, size: 20),
          label: const Text('Yakınımdakiler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        // Map Theme Button
        FloatingActionButton.extended(
          heroTag: 'btnTheme',
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          onPressed: _showThemeSelector,
          icon: const Icon(Icons.layers_rounded, size: 20),
          label: const Text('Görünüm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Harita Görünümü', style: AppTextStyles.heading3),
            ),
            ListTile(
              leading: const Icon(Icons.map_rounded),
              title: const Text('Açık (Standart)'),
              trailing: _currentMapTheme == 'light' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _currentMapTheme = 'light');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite_alt_rounded),
              title: const Text('Uydu'),
              trailing: _currentMapTheme == 'satellite' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _currentMapTheme = 'satellite');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: 'Mekan, esnaf veya etkinlik ara...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
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
      _markerCache.clear(); // Clear so markers are rebuilt with new selection/logic
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
            // 1. Search Filter
            if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery.toLowerCase())) {
              continue;
            }

            final docKey = '${doc.id}_$konum';
            LatLng? coords;
            
            if (_coordinateCache.containsKey(docKey)) {
              coords = _coordinateCache[docKey];
            } else {
              coords = _quickParseCoords(konum);
              if (coords != null) {
                _coordinateCache[docKey] = coords;
              } else if (!_pendingResolutions.contains(docKey)) {
                _resolvePosition(docKey, konum);
              }
            }

            if (coords != null) {
              // 2. Radius Filter
              if (_showRadius && _userLocation != null) {
                final dist = Geolocator.distanceBetween(
                  _userLocation!.latitude, _userLocation!.longitude,
                  coords.latitude, coords.longitude
                );
                if (dist > _radiusKm * 1000) continue;
              }

              // Build or fetch from cache
              if (_markerCache.containsKey(docKey)) {
                markers.add(_markerCache[docKey]!);
              } else {
                final m = _buildMarker(doc.id, name, coords, color, routePrefix, type, data: data);
                _markerCache[docKey] = m;
                markers.add(m);
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
      _coordinateCache[docKey] = coords;
      _pendingResolutions.remove(docKey);

      // Debounce the setState to avoid triggering 50 individual rebuilds!
      _rebuildTimer?.cancel();
      _rebuildTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {});
        }
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

  Marker _buildMarker(String id, String name, LatLng position, Color color, String routePrefix, String type, {Map<String, dynamic>? data}) {
    // Simplified Marker Widget for better performance
    return Marker(
      point: position,
      width: 110,
      height: 60,
      alignment: Alignment.topCenter, // flutter_map'te topCenter marker'ı yukarı iter, yani altını koordinata sabitler
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.vibrate();
          if (data != null) {
            _showMarkerPreview(id, name, position, color, routePrefix, type, data);
          } else if (type == 'noter' || type == 'pazar') {
             context.push(routePrefix);
          } else {
             context.push('$routePrefix$id');
          }
        },
        child: Align(
          alignment: Alignment.bottomCenter, // İçeriği (pini) kutunun en altına itiyoruz ki ucu koordinata değsin
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.4), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  )
                ],
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
      ),
    );
  }

  void _showMarkerPreview(String id, String name, LatLng position, Color color, String routePrefix, String type, Map<String, dynamic> data) {
    final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
    final rating = data['rating'] as num? ?? 0.0;
    final address = data['adres'] as String? ?? data['address'] as String? ?? '';
    
    // Calculate distance
    String distanceText = '';
    if (_userLocation != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _userLocation!.latitude, _userLocation!.longitude,
        position.latitude, position.longitude
      );
      if (distanceInMeters < 1000) {
        distanceText = '${distanceInMeters.round()} m';
      } else {
        distanceText = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle for drag
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: imageUrl.isNotEmpty 
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: color.withOpacity(0.1), child: Icon(Icons.image, color: color)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.heading3, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        if (address.isNotEmpty)
                          Text(address, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (rating > 0) ...[
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                            ],
                            if (distanceText.isNotEmpty) ...[
                              const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 16),
                              const SizedBox(width: 4),
                              Text(distanceText, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticService.selection();
                        Navigator.pop(context);
                        if (type == 'noter' || type == 'pazar') {
                           context.push(routePrefix);
                        } else {
                           context.push('$routePrefix$id');
                        }
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Detayları Gör'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        HapticService.vibrate();
                        MapHelper.openOnMap(context, position.latitude, position.longitude);
                      },
                      icon: const Icon(Icons.navigation_rounded, color: AppColors.primary),
                      tooltip: 'Yol Tarifi',
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
