import type { Shape } from '@/components/pattern-canvas';

// Flutter lib/features/home/widgets/service_grid.dart içindeki CustomPainter'lar (koordinatlar birebir).

const white = (opacity: number) => `rgba(255, 255, 255, ${opacity})`;
const primary = (opacity: number) => `rgba(76, 175, 80, ${opacity})`;

export function mapPattern(w: number, h: number): Shape[] {
  const line = (points: [number, number][]): Shape => ({
    type: 'polyline',
    points,
    strokeWidth: 1.2,
    color: primary(0.12),
  });
  return [
    line([[0, h * 0.4], [w * 0.3, h * 0.35], [w * 0.4, 0]]),
    line([[w * 0.2, 0], [w * 0.25, h * 0.6], [0, h * 0.75]]),
    line([[w * 0.8, 0], [w * 0.7, h * 0.45], [w, h * 0.55]]),
    line([[w * 0.7, h * 0.45], [w * 0.6, h]]),
    line([[w, h * 0.1], [w * 0.85, h * 0.25]]),
    line([[w * 0.5, h], [w * 0.55, h * 0.7], [w, h * 0.85]]),
  ];
}

export function newsPattern(w: number, h: number): Shape[] {
  const shapes: Shape[] = [];
  for (let i = 1; i < 6; i++) {
    const y = h * (0.15 + i * 0.15);
    const startX = w * (0.4 + (i % 2) * 0.1);
    const endX = w * (0.85 - (i % 3) * 0.05);
    shapes.push({ type: 'polyline', points: [[startX, y], [endX, y]], strokeWidth: 2, color: white(0.15) });
  }
  shapes.push({
    type: 'polyline',
    points: [[w * 0.38, h * 0.2], [w * 0.38, h * 0.8]],
    strokeWidth: 2,
    color: white(0.15),
  });
  shapes.push({ type: 'circle', center: [w * 0.9, h * 0.2], radius: 3, color: white(0.2) });
  shapes.push({ type: 'circle', center: [w * 0.88, h * 0.7], radius: 2, color: white(0.2) });
  return shapes;
}

export function busPattern(w: number, h: number): Shape[] {
  return [
    {
      type: 'polyline',
      points: [
        [w * 0.4, h * 0.2],
        [w * 0.8, h * 0.2],
        [w * 0.8, h * 0.5],
        [w * 0.5, h * 0.5],
        [w * 0.5, h * 0.8],
        [w * 0.9, h * 0.8],
      ],
      strokeWidth: 2,
      color: white(0.12),
    },
    { type: 'circle', center: [w * 0.4, h * 0.2], radius: 3, color: white(0.2) },
    { type: 'circle', center: [w * 0.8, h * 0.5], radius: 3, color: white(0.2) },
    { type: 'circle', center: [w * 0.9, h * 0.8], radius: 3, color: white(0.2) },
  ];
}

export function marketPattern(w: number, h: number): Shape[] {
  return Array.from({ length: 3 }, (_, i): Shape => {
    const xBase = w * (0.45 + i * 0.15);
    const yBase = h * (0.3 + i * 0.15);
    return {
      type: 'polyline',
      points: [[xBase, yBase], [xBase + 15, yBase - 15], [xBase + 30, yBase]],
      closed: true,
      strokeWidth: 1.5,
      color: white(0.15),
    };
  });
}

export function vefatPattern(w: number, h: number): Shape[] {
  const shapes: Shape[] = Array.from({ length: 4 }, (_, i): Shape => {
    const x = w * (0.5 + i * 0.12);
    return {
      type: 'quadratic',
      from: [x, h],
      control: [x + 20, h * 0.5],
      to: [x - 10, 0],
      strokeWidth: 1.5,
      color: white(0.12),
    };
  });
  shapes.push({ type: 'circle', center: [w * 0.85, h * 0.3], radius: 2, color: white(0.15) });
  shapes.push({ type: 'circle', center: [w * 0.75, h * 0.6], radius: 1.5, color: white(0.15) });
  return shapes;
}

export function forumPattern(w: number, h: number): Shape[] {
  return [
    {
      type: 'roundRect',
      x: w * 0.45,
      y: h * 0.1,
      width: w * 0.4,
      height: h * 0.3,
      radius: 6,
      strokeWidth: 1.5,
      color: white(0.15),
    },
    {
      type: 'roundRect',
      x: w * 0.48,
      y: h * 0.5,
      width: w * 0.32,
      height: h * 0.25,
      radius: 6,
      strokeWidth: 1.5,
      color: white(0.15),
    },
    { type: 'circle', center: [w * 0.9, h * 0.15], radius: 2.5, color: white(0.2) },
    { type: 'circle', center: [w * 0.87, h * 0.65], radius: 2, color: white(0.2) },
  ];
}
