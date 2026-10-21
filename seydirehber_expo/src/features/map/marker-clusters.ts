import type { LatLng } from '@/utils/map';

// flutter_map_marker_cluster karşılığı (maxClusterRadius 45 px, zoomToBoundsOnClick, maxZoom 17).
// Kümeleme yuvarlanmış zoom seviyesinde, Web Mercator piksel uzaklığına göre yapılır.
const TILE_SIZE = 256;

export function project(point: LatLng, zoom: number) {
  const scale = TILE_SIZE * 2 ** zoom;
  const sin = Math.min(Math.max(Math.sin((point.latitude * Math.PI) / 180), -0.9999), 0.9999);
  return {
    x: ((point.longitude + 180) / 360) * scale,
    y: (0.5 - Math.log((1 + sin) / (1 - sin)) / (4 * Math.PI)) * scale,
  };
}

export function unproject(x: number, y: number, zoom: number): LatLng {
  const scale = TILE_SIZE * 2 ** zoom;
  const longitude = (x / scale) * 360 - 180;
  const n = Math.PI - (2 * Math.PI * y) / scale;
  const latitude = (180 / Math.PI) * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
  return { latitude, longitude };
}

export type ClusterItem<T> = { key: string; position: LatLng; value: T };

export type Cluster<T> =
  | { kind: 'single'; item: ClusterItem<T> }
  | { kind: 'cluster'; key: string; position: LatLng; items: ClusterItem<T>[] };

export function clusterItems<T>(items: ClusterItem<T>[], zoom: number, radius: number): Cluster<T>[] {
  const level = Math.round(zoom);
  const groups: { x: number; y: number; items: ClusterItem<T>[] }[] = [];

  for (const item of items) {
    const p = project(item.position, level);
    const group = groups.find((g) => Math.hypot(g.x - p.x, g.y - p.y) <= radius);
    if (group) {
      group.items.push(item);
      // Küme merkezi üyelerin ortalamasıdır.
      const n = group.items.length;
      group.x += (p.x - group.x) / n;
      group.y += (p.y - group.y) / n;
    } else {
      groups.push({ x: p.x, y: p.y, items: [item] });
    }
  }

  return groups.map((g) =>
    g.items.length === 1
      ? { kind: 'single', item: g.items[0] }
      : {
          kind: 'cluster',
          key: g.items.map((i) => i.key).join('|'),
          position: unproject(g.x, g.y, level),
          items: g.items,
        },
  );
}

/** Kümedeki noktaları kenarlardan `padding` px boşlukla sığdıran zoom seviyesi. */
export function fitZoom(points: LatLng[], width: number, height: number, padding: number) {
  const projected = points.map((p) => project(p, 0));
  const dx = Math.max(...projected.map((p) => p.x)) - Math.min(...projected.map((p) => p.x));
  const dy = Math.max(...projected.map((p) => p.y)) - Math.min(...projected.map((p) => p.y));
  const zx = dx > 0 ? Math.log2((width - padding * 2) / dx) : Infinity;
  const zy = dy > 0 ? Math.log2((height - padding * 2) / dy) : Infinity;
  return Math.min(zx, zy);
}

/** Kümenin sınır kutusunun ortası. */
export function boundsCenter(points: LatLng[]): LatLng {
  const lats = points.map((p) => p.latitude);
  const lngs = points.map((p) => p.longitude);
  return {
    latitude: (Math.min(...lats) + Math.max(...lats)) / 2,
    longitude: (Math.min(...lngs) + Math.max(...lngs)) / 2,
  };
}

/**
 * Daha fazla yakınlaşılamayan kümeyi açar (spiderfy): işaretçiler merkez etrafında daireye
 * (9 ve üstü için spirale) dizilir. Değerler flutter_map_marker_cluster varsayılanlarına yakın.
 */
export function spiderfyPositions(center: LatLng, count: number, zoom: number): LatLng[] {
  const c = project(center, zoom);
  if (count < 9) {
    const legLength = Math.max(40, (count * 45) / (2 * Math.PI));
    return Array.from({ length: count }, (_, i) => {
      const angle = (i / count) * 2 * Math.PI;
      return unproject(c.x + legLength * Math.cos(angle), c.y + legLength * Math.sin(angle), zoom);
    });
  }
  let legLength = 11;
  let angle = 0;
  return Array.from({ length: count }, () => {
    angle += 28 / legLength + 0.0005;
    const point = unproject(c.x + legLength * Math.cos(angle), c.y + legLength * Math.sin(angle), zoom);
    legLength += (2 * Math.PI * 5) / angle;
    return point;
  });
}
