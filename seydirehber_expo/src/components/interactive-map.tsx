import { MaterialIcons } from '@expo/vector-icons';
import { Camera, Map, Marker, type StyleSpecification } from '@maplibre/maplibre-react-native';
import { StyleSheet, Text, View } from 'react-native';

import { colors, fonts } from '@/theme';
import type { LatLng } from '@/utils/map';

// Flutter lib/core/widgets/interactive_map_widget.dart karşılığı: OSM katmanı, zoom 15 (10–18),
// sürükleme / iki parmakla yakınlaştırma / çift dokunma açık, döndürme kapalı.
const OSM_STYLE: StyleSpecification = {
  version: 8,
  sources: {
    osm: {
      type: 'raster',
      tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
      tileSize: 256,
    },
  },
  layers: [{ id: 'osm', type: 'raster', source: 'osm' }],
};

type InteractiveMapProps = {
  position: LatLng;
  title: string;
};

export function InteractiveMap({ position, title }: InteractiveMapProps) {
  if (!Number.isFinite(position.latitude) || !Number.isFinite(position.longitude)) {
    return (
      <View style={[styles.container, styles.center]}>
        <Text>Geçersiz konum verisi</Text>
      </View>
    );
  }

  const label = title.length > 20 ? `${title.slice(0, 17)}...` : title;

  return (
    <View style={styles.container}>
      <Map
        style={StyleSheet.absoluteFill}
        mapStyle={OSM_STYLE}
        touchRotate={false}
        touchPitch={false}
        compass={false}
        logo={false}
        attribution={false}
        scaleBar={false}>
        <Camera
          initialViewState={{ center: [position.longitude, position.latitude], zoom: 15 }}
          minZoom={10}
          maxZoom={18}
        />
        <Marker lngLat={[position.longitude, position.latitude]} anchor="bottom">
          <View style={styles.marker}>
            <View style={styles.label}>
              <Text style={styles.labelText}>{label}</Text>
            </View>
            <MaterialIcons name="location-on" size={40} color="#F44336" />
          </View>
        </Marker>
      </Map>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: 200,
    borderRadius: 24,
    backgroundColor: '#F5F5F5',
  },
  center: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  marker: {
    width: 120,
    alignItems: 'center',
  },
  label: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 10,
    backgroundColor: colors.primaryDark,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 3,
  },
  labelText: {
    fontFamily: fonts.bold,
    fontSize: 10,
    color: colors.white,
    textAlign: 'center',
  },
});
