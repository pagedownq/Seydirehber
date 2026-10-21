import { useEffect, useState } from 'react';

import { getCoordinates, type LatLng } from '@/utils/map';

// Flutter FutureBuilder<LatLng?>(future: MapHelper.getCoordinates(konum)) karşılığı.
export type CoordinatesState = { status: 'loading' } | { status: 'done'; coords: LatLng | null };

export function useCoordinates(locationData: string | null | undefined): CoordinatesState {
  const [result, setResult] = useState<{ input: string; coords: LatLng | null } | null>(null);
  const input = locationData ?? '';

  useEffect(() => {
    if (!input) return;
    let cancelled = false;
    getCoordinates(input).then((coords) => {
      if (!cancelled) setResult({ input, coords });
    });
    return () => {
      cancelled = true;
    };
  }, [input]);

  if (!input) return { status: 'done', coords: null };
  return result?.input === input ? { status: 'done', coords: result.coords } : { status: 'loading' };
}
