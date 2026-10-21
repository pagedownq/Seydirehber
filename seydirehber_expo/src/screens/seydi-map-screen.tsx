import { MaterialIcons } from '@expo/vector-icons';
import {
  Camera,
  type CameraRef,
  GeoJSONSource,
  Layer,
  Map,
  Marker,
  type StyleSpecification,
} from '@maplibre/maplibre-react-native';
import { type Href, router } from 'expo-router';
import { type ComponentProps, useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Image,
  Keyboard,
  Linking,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { AppBar } from '@/components/app-bar';
import { BottomSheet } from '@/components/bottom-sheet';
import { showSnackbar } from '@/components/snackbar';
import type { LiveDoc, LiveQueryState } from '@/features/firestore/live-query';
import {
  useAllCompanies,
  useAllEvents,
  useAllPlaces,
  useNoterler,
  usePazarlar,
} from '@/features/home/home-queries';
import {
  boundsCenter,
  type Cluster,
  type ClusterItem,
  clusterItems,
  fitZoom,
  spiderfyPositions,
} from '@/features/map/marker-clusters';
import { distanceBetween, type LocationDialog, useUserLocation } from '@/features/map/use-user-location';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';
import { str } from '@/utils/firestore-values';
import { getCoordinates, type LatLng, openOnMap } from '@/utils/map';

// Flutter lib/features/map/screens/seydi_map_screen.dart karşılığı.
type IconName = ComponentProps<typeof MaterialIcons>['name'];
type MarkerType = 'place' | 'company' | 'event' | 'noter' | 'pazar';
type MapMarker = {
  id: string;
  name: string;
  type: MarkerType;
  color: string;
  routePrefix: string;
  data: Record<string, unknown>;
};

const FILTERS = ['Tümü', 'Yerler', 'Firmalar', 'Etkinlikler', 'Noterler', 'Pazarlar'] as const;
type Filter = (typeof FILTERS)[number];

const FILTER_ICONS: Record<Filter, IconName> = {
  Tümü: 'explore',
  Yerler: 'park',
  Firmalar: 'business',
  Etkinlikler: 'celebration',
  Noterler: 'gavel',
  Pazarlar: 'shopping-basket',
};

// Flutter Colors.blue / green / purple / red / orange
const MARKER_COLORS = {
  blue: '#2196F3',
  green: '#4CAF50',
  purple: '#9C27B0',
  red: '#F44336',
  orange: '#FF9800',
};

// Seydişehir merkezi
const SEYDISEHIR_CENTER: LatLng = { latitude: 37.418, longitude: 31.846 };
const RADIUS_KM = 0.5;
const CLUSTER_RADIUS = 45;
const CLUSTER_MAX_ZOOM = 17;

/** Sırayla üst üste çizilen raster katmanlar; maxzoom'dan sonra karolar büyütülerek kullanılır. */
function rasterStyle(layers: { tiles: string; maxzoom?: number }[]): StyleSpecification {
  return {
    version: 8,
    sources: Object.fromEntries(
      layers.map(({ tiles, maxzoom }, i) => [`l${i}`, { type: 'raster', tiles: [tiles], tileSize: 256, maxzoom }]),
    ),
    layers: layers.map((_, i) => ({ id: `l${i}`, type: 'raster', source: `l${i}` })),
  };
}

const ESRI = 'https://server.arcgisonline.com/ArcGIS/rest/services';

const MAP_STYLES = {
  // Flutter CARTO light_all kullanıyordu; CARTO artık API anahtarı istiyor ("API KEY REQUIRED" karosu).
  // Anahtarsız en yakın görünüm: Esri açık gri altlık + etiket katmanı (16'dan sonra veri yok, büyütülür).
  light: rasterStyle([
    { tiles: `${ESRI}/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}`, maxzoom: 16 },
    { tiles: `${ESRI}/Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}`, maxzoom: 16 },
  ]),
  satellite: rasterStyle([{ tiles: `${ESRI}/World_Imagery/MapServer/tile/{z}/{y}/{x}` }]),
};
type MapTheme = keyof typeof MAP_STYLES;

// İşaretçiye dokunuş haritanın onPress'ine de düşüyor; hemen ardından gelen harita dokunuşu yok sayılır.
let lastMarkerPressAt = 0;
const markMarkerPress = () => {
  lastMarkerPressAt = Date.now();
};
const isRecentMarkerPress = () => Date.now() - lastMarkerPressAt < 400;

function withOpacity(hex: string, opacity: number) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${opacity})`;
}

const isValidCoords = (lat: number, lng: number) =>
  Number.isFinite(lat) && Number.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

function quickParseCoords(location: string): LatLng | null {
  if (!location.includes(',')) return null;
  const parts = location.split(',');
  if (parts.length !== 2) return null;
  // Dart double.tryParse gibi: sayı dışı içerik varsa null.
  const lat = Number(parts[0].trim());
  const lng = Number(parts[1].trim());
  if (parts[0].trim() === '' || parts[1].trim() === '') return null;
  return isValidCoords(lat, lng) ? { latitude: lat, longitude: lng } : null;
}

/** Ekran genişliğindeki 500 m'lik çember (Flutter CircleLayer, useRadiusInMeter). */
function circlePolygon(center: LatLng, radiusMeters: number): GeoJSON.Feature<GeoJSON.Polygon> {
  const coords: [number, number][] = [];
  const latRad = (center.latitude * Math.PI) / 180;
  for (let i = 0; i <= 64; i++) {
    const angle = (i / 64) * 2 * Math.PI;
    const dLat = (radiusMeters * Math.cos(angle)) / 111320;
    const dLng = (radiusMeters * Math.sin(angle)) / (111320 * Math.cos(latRad));
    coords.push([center.longitude + dLng, center.latitude + dLat]);
  }
  return { type: 'Feature', properties: {}, geometry: { type: 'Polygon', coordinates: [coords] } };
}

function openMarkerRoute(marker: MapMarker) {
  if (marker.type === 'noter' || marker.type === 'pazar') router.push(marker.routePrefix as Href);
  else router.push(`${marker.routePrefix}${marker.id}` as Href);
}

export function SeydiMapScreen() {
  const places = useAllPlaces();
  const companies = useAllCompanies();
  const events = useAllEvents();
  const noterler = useNoterler();
  const pazarlar = usePazarlar();

  const cameraRef = useRef<CameraRef>(null);
  const { userLocation, recheck, dialog, closeDialog } = useUserLocation();

  const [selectedFilter, setSelectedFilter] = useState<Filter>('Tümü');
  const [mapTheme, setMapTheme] = useState<MapTheme>('light');
  const [showRadius, setShowRadius] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [zoom, setZoom] = useState(14.5);
  const [viewport, setViewport] = useState({ width: 0, height: 0 });
  const [themeSheetVisible, setThemeSheetVisible] = useState(false);
  const [preview, setPreview] = useState<{ marker: MapMarker; position: LatLng } | null>(null);
  const [spiderfied, setSpiderfied] = useState<string | null>(null);

  // Koordinat önbelleği: "lat, lng" olmayan konumlar (link, DMS, adres) arka planda çözülür.
  const [resolved, setResolved] = useState<Record<string, LatLng | null>>({});
  const pending = useRef(new Set<string>());
  const batch = useRef<Record<string, LatLng | null>>({});
  const rebuildTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const sources = useMemo(() => {
    const list: { state: LiveQueryState; type: MarkerType; color: string; routePrefix: string; filter: Filter }[] = [
      { state: places, type: 'place', color: MARKER_COLORS.blue, routePrefix: '/places/', filter: 'Yerler' },
      { state: companies, type: 'company', color: MARKER_COLORS.green, routePrefix: '/companies/', filter: 'Firmalar' },
      { state: events, type: 'event', color: MARKER_COLORS.purple, routePrefix: '/events/', filter: 'Etkinlikler' },
      { state: noterler, type: 'noter', color: MARKER_COLORS.red, routePrefix: '/noterler', filter: 'Noterler' },
      { state: pazarlar, type: 'pazar', color: MARKER_COLORS.orange, routePrefix: '/pazarlar', filter: 'Pazarlar' },
    ];
    return list;
  }, [places, companies, events, noterler, pazarlar]);

  const isLoading = sources.some((s) => s.state.status === 'loading');

  // Çözülmesi gereken konumları arka planda koordinata çevir (150 ms'lik toplu güncelleme).
  useEffect(() => {
    for (const source of sources) {
      for (const doc of source.state.docs) {
        const konum = str(doc.data.konum);
        if (!konum) continue;
        const key = `${doc.id}_${konum}`;
        if (quickParseCoords(konum) || key in resolved || pending.current.has(key)) continue;
        pending.current.add(key);
        getCoordinates(konum).then((coords) => {
          pending.current.delete(key);
          batch.current[key] = coords && isValidCoords(coords.latitude, coords.longitude) ? coords : null;
          if (rebuildTimer.current) clearTimeout(rebuildTimer.current);
          rebuildTimer.current = setTimeout(() => {
            const next = batch.current;
            batch.current = {};
            setResolved((prev) => ({ ...prev, ...next }));
          }, 150);
        });
      }
    }
  }, [sources, resolved]);

  useEffect(
    () => () => {
      if (rebuildTimer.current) clearTimeout(rebuildTimer.current);
    },
    [],
  );

  const items = useMemo(() => {
    const result: ClusterItem<MapMarker>[] = [];
    const query = searchQuery.toLowerCase();
    for (const source of sources) {
      if (selectedFilter !== 'Tümü' && selectedFilter !== source.filter) continue;
      for (const doc of source.state.docs as LiveDoc[]) {
        const data = doc.data;
        const name = typeof data.ad === 'string' ? data.ad : source.type === 'noter' ? 'Noter' : 'İsimsiz';
        const konum = str(data.konum);
        if (!konum) continue;
        // 1. Arama filtresi
        if (query && !name.toLowerCase().includes(query)) continue;

        const key = `${doc.id}_${konum}`;
        const coords = quickParseCoords(konum) ?? resolved[key] ?? null;
        if (!coords) continue;

        // 2. Yarıçap filtresi
        if (showRadius && userLocation && distanceBetween(userLocation, coords) > RADIUS_KM * 1000) continue;

        result.push({
          key,
          position: coords,
          value: { id: doc.id, name, type: source.type, color: source.color, routePrefix: source.routePrefix, data },
        });
      }
    }
    return result;
  }, [sources, selectedFilter, searchQuery, resolved, showRadius, userLocation]);

  const clusters = useMemo(() => clusterItems(items, zoom, CLUSTER_RADIUS), [items, zoom]);

  const moveTo = (position: LatLng, targetZoom: number) =>
    cameraRef.current?.jumpTo({ center: [position.longitude, position.latitude], zoom: targetZoom });

  const onMyLocation = async () => {
    haptics.vibrate();
    if (userLocation) {
      moveTo(userLocation, 15);
      return;
    }
    // Konum yoksa tekrar almayı dene
    const location = await recheck();
    if (location) {
      moveTo(location, 15);
    } else {
      moveTo(SEYDISEHIR_CENTER, 14.5);
      showSnackbar({
        message: 'Konum alınamadı. Lütfen konum servislerinizi ve izinlerinizi kontrol edin.',
        durationMs: 2000,
      });
    }
  };

  const onMarkerPress = (item: ClusterItem<MapMarker>) => {
    markMarkerPress();
    haptics.vibrate();
    // centerMarkerOnClick
    cameraRef.current?.easeTo({
      center: [item.position.longitude, item.position.latitude],
      duration: 300,
    });
    setPreview({ marker: item.value, position: item.position });
  };

  const onClusterPress = (cluster: Extract<Cluster<MapMarker>, { kind: 'cluster' }>) => {
    markMarkerPress();
    haptics.selection();
    const points = cluster.items.map((i) => i.position);
    const target = Math.min(CLUSTER_MAX_ZOOM, fitZoom(points, viewport.width, viewport.height, 50));
    // Yakınlaşınca küme gerçekten ayrılacaksa yakınlaş; aynı/çok yakın konumdakiler ayrılmaz, doğrudan aç.
    const splitsOnZoom = target > zoom + 0.05 && clusterItems(cluster.items, target, CLUSTER_RADIUS).length > 1;
    if (splitsOnZoom) {
      const center = boundsCenter(points);
      cameraRef.current?.easeTo({ center: [center.longitude, center.latitude], zoom: target, duration: 500 });
    } else {
      setSpiderfied(cluster.key);
    }
  };

  const renderedMarkers = clusters.flatMap((cluster) => {
    if (cluster.kind === 'single') {
      return [<PlaceMarker key={cluster.item.key} item={cluster.item} onPress={onMarkerPress} />];
    }
    if (cluster.key === spiderfied) {
      const positions = spiderfyPositions(cluster.position, cluster.items.length, Math.round(zoom));
      return cluster.items.map((item, index) => (
        <PlaceMarker
          key={item.key}
          item={{ ...item, position: positions[index] }}
          onPress={() => onMarkerPress(item)}
        />
      ));
    }
    return [
      <Marker key={cluster.key} id={cluster.key} lngLat={[cluster.position.longitude, cluster.position.latitude]} anchor="center">
        <Pressable onPress={() => onClusterPress(cluster)} style={styles.cluster}>
          <Text style={styles.clusterText}>{cluster.items.length}</Text>
        </Pressable>
      </Marker>,
    ];
  });

  return (
    <View style={styles.container}>
      <AppBar
        title="Seydi Harita"
        actions={
          <>
            <Pressable hitSlop={4} onPress={onMyLocation} style={styles.locationButton}>
              <View style={styles.locationButtonInner}>
                <MaterialIcons name="my-location" size={20} color={colors.primary} />
              </View>
            </Pressable>
            <View style={{ width: 8 }} />
          </>
        }
      />
      <View
        style={{ flex: 1 }}
        onLayout={(e) => setViewport({ width: e.nativeEvent.layout.width, height: e.nativeEvent.layout.height })}>
        <Map
          style={StyleSheet.absoluteFill}
          mapStyle={MAP_STYLES[mapTheme]}
          touchRotate={false}
          touchPitch={false}
          compass={false}
          logo={false}
          attribution={false}
          scaleBar={false}
          onPress={() => {
            if (!isRecentMarkerPress()) setSpiderfied(null);
          }}
          onRegionDidChange={(e) => {
            const next = e.nativeEvent.zoom;
            if (Math.round(next) !== Math.round(zoom)) setSpiderfied(null);
            setZoom(next);
          }}>
          <Camera
            ref={cameraRef}
            initialViewState={{ center: [SEYDISEHIR_CENTER.longitude, SEYDISEHIR_CENTER.latitude], zoom: 14.5 }}
            minZoom={10}
            maxZoom={18}
          />
          {showRadius && userLocation && (
            <GeoJSONSource id="radius" data={circlePolygon(userLocation, RADIUS_KM * 1000)}>
              <Layer id="radius-fill" type="fill" paint={{ 'fill-color': withOpacity(colors.primary, 0.1) }} />
              <Layer
                id="radius-line"
                type="line"
                paint={{ 'line-color': withOpacity(colors.primary, 0.5), 'line-width': 2 }}
              />
            </GeoJSONSource>
          )}
          {renderedMarkers}
          {userLocation && (
            // Flutter'da kullanıcı işaretçisi 60x60 kutuda ortalanmış ve alignment topCenter ile
            // noktanın üstüne yerleşiyor (mavi nokta gerçek konumun ~30 px üstünde); aynen korundu.
            <Marker id="user-location" lngLat={[userLocation.longitude, userLocation.latitude]} anchor="bottom">
              <View style={styles.userMarker}>
                <View style={styles.userHalo} />
                <View style={styles.userDot} />
              </View>
            </Marker>
          )}
        </Map>

        {/* Üstte yüzen arama ve filtre çubuğu */}
        <View style={styles.topOverlay} pointerEvents="box-none">
          <SearchBar value={searchQuery} onChange={setSearchQuery} />
          <FilterBar
            selected={selectedFilter}
            onSelect={(filter) => {
              if (filter !== selectedFilter) {
                haptics.selection();
                setSelectedFilter(filter);
                setSpiderfied(null);
              }
            }}
          />
        </View>

        {isLoading && (
          <View style={styles.loading}>
            <ActivityIndicator size={20} color={colors.primary} />
          </View>
        )}

        {/* Harita kontrolleri (görünüm ve yarıçap) */}
        <View style={styles.controls}>
          <ExtendedFab
            icon="radar"
            label="Yakınımdakiler"
            active={showRadius}
            onPress={() => {
              haptics.selection();
              setShowRadius((v) => !v);
              setSpiderfied(null);
            }}
          />
          <View style={{ height: 12 }} />
          <ExtendedFab icon="layers" label="Görünüm" active={false} onPress={() => setThemeSheetVisible(true)} />
        </View>
      </View>

      <ThemeSheet
        visible={themeSheetVisible}
        current={mapTheme}
        onClose={() => setThemeSheetVisible(false)}
        onSelect={(theme) => {
          setMapTheme(theme);
          setThemeSheetVisible(false);
        }}
      />
      <MarkerPreviewSheet preview={preview} userLocation={userLocation} onClose={() => setPreview(null)} />
      <LocationDialogModal dialog={dialog} onClose={closeDialog} />
    </View>
  );
}

function PlaceMarker({
  item,
  onPress,
}: {
  item: ClusterItem<MapMarker>;
  onPress: (item: ClusterItem<MapMarker>) => void;
}) {
  const { name, color } = item.value;
  return (
    <Marker id={item.key} lngLat={[item.position.longitude, item.position.latitude]} anchor="bottom">
      {/* İçerik kutunun altına itilir ki pinin ucu koordinata değsin */}
      <Pressable onPress={() => onPress(item)} style={styles.marker}>
        <View style={[styles.markerLabel, { borderColor: withOpacity(color, 0.4) }]}>
          <Text style={styles.markerLabelText} numberOfLines={1}>
            {name.length > 15 ? `${name.substring(0, 12)}...` : name}
          </Text>
        </View>
        <MaterialIcons name="location-on" size={28} color={color} />
      </Pressable>
    </Marker>
  );
}

function SearchBar({ value, onChange }: { value: string; onChange: (value: string) => void }) {
  return (
    <View style={styles.searchWrapper}>
      <View style={styles.search}>
        <MaterialIcons name="search" size={22} color={colors.primary} style={{ marginHorizontal: 12 }} />
        <TextInput
          value={value}
          onChangeText={onChange}
          placeholder="Mekan, esnaf veya etkinlik ara..."
          placeholderTextColor="#9E9E9E"
          style={styles.searchInput}
        />
        {value.length > 0 && (
          <Pressable
            hitSlop={8}
            style={styles.searchClear}
            onPress={() => {
              onChange('');
              Keyboard.dismiss();
            }}>
            <MaterialIcons name="close" size={20} color="#9E9E9E" />
          </Pressable>
        )}
      </View>
    </View>
  );
}

function FilterBar({ selected, onSelect }: { selected: Filter; onSelect: (filter: Filter) => void }) {
  return (
    <FlatList
      horizontal
      data={FILTERS}
      keyExtractor={(item) => item}
      showsHorizontalScrollIndicator={false}
      style={{ height: 40, flexGrow: 0 }}
      contentContainerStyle={{ paddingHorizontal: 16 }}
      renderItem={({ item }) => {
        const isSelected = item === selected;
        return (
          <Pressable
            onPress={() => onSelect(item)}
            style={[styles.filterChip, isSelected ? styles.filterSelected : styles.filterIdle]}>
            <MaterialIcons name={FILTER_ICONS[item]} size={16} color={isSelected ? colors.white : colors.primary} />
            <Text
              style={[
                styles.filterText,
                {
                  color: isSelected ? colors.white : colors.black87,
                  fontFamily: isSelected ? fonts.bold : fonts.semiBold,
                },
              ]}>
              {item}
            </Text>
          </Pressable>
        );
      }}
    />
  );
}

function ExtendedFab({
  icon,
  label,
  active,
  onPress,
}: {
  icon: IconName;
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  const foreground = active ? colors.white : colors.primary;
  return (
    <Pressable onPress={onPress} style={[styles.fab, { backgroundColor: active ? colors.primary : colors.white }]}>
      <MaterialIcons name={icon} size={20} color={foreground} />
      <Text style={[styles.fabLabel, { color: foreground }]}>{label}</Text>
    </Pressable>
  );
}

function ThemeSheet({
  visible,
  current,
  onClose,
  onSelect,
}: {
  visible: boolean;
  current: MapTheme;
  onClose: () => void;
  onSelect: (theme: MapTheme) => void;
}) {
  const options: { theme: MapTheme; icon: IconName; label: string }[] = [
    { theme: 'light', icon: 'map', label: 'Açık (Standart)' },
    { theme: 'satellite', icon: 'satellite-alt', label: 'Uydu' },
  ];
  return (
    <BottomSheet visible={visible} onClose={onClose} fillBottomInset={false}>
      <View style={styles.floatingSheet}>
        <View style={styles.handle} />
        <Text style={[typography.heading3, { padding: 16 }]}>Harita Görünümü</Text>
        {options.map((option) => (
          <Pressable key={option.theme} onPress={() => onSelect(option.theme)} style={styles.listTile}>
            <MaterialIcons name={option.icon} size={24} color="#49454F" />
            <Text style={[typography.bodyLarge, { flex: 1, marginLeft: 16 }]}>{option.label}</Text>
            {current === option.theme && <MaterialIcons name="check" size={24} color={colors.primary} />}
          </Pressable>
        ))}
        <View style={{ height: 16 }} />
      </View>
    </BottomSheet>
  );
}

function MarkerPreviewSheet({
  preview,
  userLocation,
  onClose,
}: {
  preview: { marker: MapMarker; position: LatLng } | null;
  userLocation: LatLng | null;
  onClose: () => void;
}) {
  // Kapanırken içerik boşalmasın diye son önizleme tutulur.
  const [last, setLast] = useState(preview);
  if (preview && preview !== last) setLast(preview);
  const shown = preview ?? last;
  if (!shown) return null;

  const { marker, position } = shown;
  const data = marker.data;
  const imageUrl = str(data.image_url) || str(data.gorsel);
  const rating = typeof data.rating === 'number' ? data.rating : 0;
  const address = str(data.adres) || str(data.address);

  // Mesafe hesapla
  let distanceText = '';
  if (userLocation) {
    const meters = distanceBetween(userLocation, position);
    distanceText = meters < 1000 ? `${Math.round(meters)} m` : `${(meters / 1000).toFixed(1)} km`;
  }

  return (
    <BottomSheet visible={preview != null} onClose={onClose} fillBottomInset={false}>
      <View style={[styles.floatingSheet, styles.previewShadow]}>
        {/* Flutter'daki tutamak kutusu renksiz olduğu için görünmüyor; yalnızca boşluk bırakıyor. */}
        <View style={{ height: 28 }} />
        <View style={styles.previewRow}>
          <View style={styles.previewImage}>
            {imageUrl ? (
              <Image source={{ uri: imageUrl }} style={StyleSheet.absoluteFill} resizeMode="cover" />
            ) : (
              <View style={[StyleSheet.absoluteFill, styles.center, { backgroundColor: withOpacity(marker.color, 0.1) }]}>
                <MaterialIcons name="image" size={24} color={marker.color} />
              </View>
            )}
          </View>
          <View style={{ flex: 1, marginLeft: 16 }}>
            <Text style={typography.heading3} numberOfLines={1}>
              {marker.name}
            </Text>
            <View style={{ height: 4 }} />
            {address.length > 0 && (
              <Text style={typography.bodySmall} numberOfLines={1}>
                {address}
              </Text>
            )}
            <View style={{ height: 8 }} />
            <View style={styles.previewMeta}>
              {rating > 0 && (
                <>
                  <MaterialIcons name="star" size={18} color="#FFC107" />
                  <Text style={[styles.metaText, { marginLeft: 4, marginRight: 12 }]}>{rating.toFixed(1)}</Text>
                </>
              )}
              {distanceText.length > 0 && (
                <>
                  <MaterialIcons name="near-me" size={16} color={colors.primary} />
                  <Text style={[styles.metaText, { marginLeft: 4, color: colors.primary }]}>{distanceText}</Text>
                </>
              )}
            </View>
          </View>
        </View>
        <View style={styles.previewActions}>
          <Pressable
            onPress={() => {
              haptics.selection();
              onClose();
              openMarkerRoute(marker);
            }}
            style={styles.detailButton}>
            <MaterialIcons name="info-outline" size={18} color={colors.white} />
            <Text style={styles.detailButtonText}>Detayları Gör</Text>
          </Pressable>
          <Pressable
            accessibilityLabel="Yol Tarifi"
            onPress={() => {
              haptics.vibrate();
              openOnMap(position.latitude, position.longitude);
            }}
            style={styles.navigationButton}>
            <MaterialIcons name="navigation" size={24} color={colors.primary} />
          </Pressable>
        </View>
      </View>
    </BottomSheet>
  );
}

function LocationDialogModal({ dialog, onClose }: { dialog: LocationDialog; onClose: () => void }) {
  return (
    <Modal visible={dialog != null} transparent animationType="fade" statusBarTranslucent onRequestClose={onClose}>
      <View style={styles.dialogBarrier}>
        <View style={styles.dialog}>
          {dialog === 'permission-denied' ? (
            <>
              <View style={[styles.dialogIcon, { backgroundColor: withOpacity(colors.error, 0.1) }]}>
                <MaterialIcons name="security" size={32} color={colors.error} />
              </View>
              <Text style={[typography.heading2, styles.dialogTitle]}>Konum İzni Gerekli</Text>
              <Text style={styles.dialogContent}>
                Uygulama özelliklerini tam kullanabilmek için konum iznine ihtiyacımız var. Lütfen uygulama ayarlarından izin
                verin.
              </Text>
              <View style={styles.dialogRow}>
                <Pressable
                  style={styles.dialogTextButton}
                  onPress={() => {
                    haptics.selection();
                    onClose();
                  }}>
                  <Text style={[styles.dialogTextButtonLabel, { color: colors.primary }]}>Vazgeç</Text>
                </Pressable>
                <View style={{ width: 12 }} />
                <Pressable
                  style={[styles.dialogPrimary, { flex: 1 }]}
                  onPress={() => {
                    haptics.vibrate();
                    onClose();
                    Linking.openSettings();
                  }}>
                  <Text style={styles.dialogPrimaryLabel}>Ayarları Aç</Text>
                </Pressable>
              </View>
            </>
          ) : (
            <>
              <View style={[styles.dialogIcon, { backgroundColor: withOpacity(colors.warning, 0.1) }]}>
                <MaterialIcons name="location-off" size={32} color={colors.warning} />
              </View>
              <Text style={[styles.dialogTitle, { fontFamily: fonts.bold, fontSize: 20, color: colors.textPrimary }]}>
                Konum Servisi Kapalı
              </Text>
              <Text style={styles.dialogContent}>
                Cihazınızın konum servisi (GPS) kapalı. Lütfen Ayarlar {'>'} Gizlilik ve Güvenlik {'>'} Konum Servisleri
                adımlarını izleyerek aktif hale getirin.
              </Text>
              <Pressable
                style={[styles.dialogPrimary, { alignSelf: 'stretch' }]}
                onPress={() => {
                  haptics.vibrate();
                  onClose();
                  Linking.openSettings();
                }}>
                <Text style={styles.dialogPrimaryLabel}>Ayarları Aç</Text>
              </Pressable>
              <Pressable style={[styles.dialogTextButton, { flex: 0, paddingHorizontal: 12 }]} onPress={onClose}>
                <Text style={[styles.dialogTextButtonLabel, { color: colors.textLight, fontFamily: fonts.medium }]}>
                  Vazgeç
                </Text>
              </Pressable>
            </>
          )}
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  center: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  locationButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  locationButtonInner: {
    padding: 8,
    borderRadius: 999,
    backgroundColor: colors.primarySurface,
  },
  topOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
  searchWrapper: {
    paddingTop: 12,
    paddingHorizontal: 16,
    paddingBottom: 8,
  },
  search: {
    height: 48,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    shadowColor: '#000000',
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  searchInput: {
    flex: 1,
    height: 48,
    paddingVertical: 0,
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textPrimary,
  },
  searchClear: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  filterChip: {
    height: 40,
    marginRight: 8,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 20,
    borderWidth: 1,
  },
  filterSelected: {
    backgroundColor: colors.primary,
    borderColor: 'transparent',
    shadowColor: colors.primary,
    shadowOpacity: 0.3,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 4,
  },
  filterIdle: {
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    borderColor: 'rgba(158, 158, 158, 0.2)',
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  filterText: {
    marginLeft: 6,
    fontSize: 12,
    letterSpacing: -0.2,
  },
  loading: {
    position: 'absolute',
    top: 120,
    right: 20,
    padding: 8,
    borderRadius: 999,
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    shadowColor: '#000000',
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  controls: {
    position: 'absolute',
    right: 16,
    bottom: 30,
    alignItems: 'flex-end',
  },
  fab: {
    height: 48,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
    elevation: 6,
  },
  fabLabel: {
    marginLeft: 8,
    fontFamily: fonts.bold,
    fontSize: 13,
  },
  cluster: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 20,
    backgroundColor: colors.primary,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3,
  },
  clusterText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.white,
  },
  marker: {
    width: 110,
    height: 60,
    alignItems: 'center',
    justifyContent: 'flex-end',
  },
  markerLabel: {
    maxWidth: 110,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
    borderWidth: 1,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  markerLabelText: {
    fontFamily: fonts.bold,
    fontSize: 9,
    color: colors.black87,
    textAlign: 'center',
  },
  userMarker: {
    width: 60,
    height: 60,
    alignItems: 'center',
    justifyContent: 'center',
  },
  userHalo: {
    position: 'absolute',
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: 'rgba(33, 150, 243, 0.2)',
  },
  userDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: colors.white,
    backgroundColor: '#2196F3',
    shadowColor: '#2196F3',
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 3,
  },
  floatingSheet: {
    margin: 16,
    borderRadius: 24,
    backgroundColor: colors.white,
  },
  previewShadow: {
    shadowColor: '#000000',
    shadowOpacity: 0.15,
    shadowRadius: 20,
    shadowOffset: { width: 0, height: -5 },
    elevation: 8,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    marginVertical: 12,
    borderRadius: 2,
    backgroundColor: '#E0E0E0',
  },
  listTile: {
    minHeight: 56,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },
  previewRow: {
    paddingHorizontal: 16,
    paddingBottom: 20,
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  previewImage: {
    width: 100,
    height: 100,
    borderRadius: 16,
    overflow: 'hidden',
  },
  previewMeta: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  metaText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.textPrimary,
  },
  previewActions: {
    paddingHorizontal: 16,
    paddingBottom: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },
  detailButton: {
    flex: 1,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.primary,
    elevation: 1,
  },
  detailButtonText: {
    marginLeft: 8,
    fontFamily: fonts.medium,
    fontSize: 14,
    color: colors.white,
  },
  navigationButton: {
    width: 48,
    height: 48,
    marginLeft: 12,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.primarySurface,
  },
  dialogBarrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    backgroundColor: colors.barrier,
  },
  dialog: {
    alignSelf: 'stretch',
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingVertical: 32,
    borderRadius: 24,
    backgroundColor: colors.white,
  },
  dialogIcon: {
    padding: 16,
    borderRadius: 999,
  },
  dialogTitle: {
    marginTop: 24,
    textAlign: 'center',
  },
  dialogContent: {
    marginTop: 12,
    marginBottom: 32,
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 19.6,
    color: colors.textSecondary,
    textAlign: 'center',
  },
  dialogRow: {
    alignSelf: 'stretch',
    flexDirection: 'row',
  },
  dialogTextButton: {
    flex: 1,
    minHeight: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dialogTextButtonLabel: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
  },
  dialogPrimary: {
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  dialogPrimaryLabel: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.white,
  },
});
