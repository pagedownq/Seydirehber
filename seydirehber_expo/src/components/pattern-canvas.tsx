import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

// Flutter CustomPaint ile çizilen basit dekoratif desenlerin karşılığı. react-native-svg (native modül)
// eklememek için çizgiler döndürülmüş ince View'larla, daireler yuvarlak View'larla çizilir.
// Koordinatlar Flutter painter'larındaki gibi piksel cinsinden, çizim alanının boyutuna göre hesaplanır.

export type Point = [number, number];

export type Shape =
  | { type: 'polyline'; points: Point[]; strokeWidth: number; color: string; closed?: boolean }
  | { type: 'quadratic'; from: Point; control: Point; to: Point; strokeWidth: number; color: string }
  | { type: 'circle'; center: Point; radius: number; color: string }
  | { type: 'roundRect'; x: number; y: number; width: number; height: number; radius: number; strokeWidth: number; color: string };

type PatternCanvasProps = {
  /** Çizim alanı boyutuna göre şekilleri üretir (Flutter paint(canvas, size)). */
  draw: (width: number, height: number) => Shape[];
};

const CURVE_SEGMENTS = 16;

function quadraticPoints(from: Point, control: Point, to: Point): Point[] {
  return Array.from({ length: CURVE_SEGMENTS + 1 }, (_, i) => {
    const t = i / CURVE_SEGMENTS;
    const u = 1 - t;
    return [
      u * u * from[0] + 2 * u * t * control[0] + t * t * to[0],
      u * u * from[1] + 2 * u * t * control[1] + t * t * to[1],
    ];
  });
}

function Segment({ a, b, strokeWidth, color }: { a: Point; b: Point; strokeWidth: number; color: string }) {
  const dx = b[0] - a[0];
  const dy = b[1] - a[1];
  const length = Math.hypot(dx, dy);
  return (
    <View
      style={{
        position: 'absolute',
        left: (a[0] + b[0]) / 2 - length / 2,
        top: (a[1] + b[1]) / 2 - strokeWidth / 2,
        width: length,
        height: strokeWidth,
        borderRadius: strokeWidth / 2,
        backgroundColor: color,
        transform: [{ rotate: `${Math.atan2(dy, dx)}rad` }],
      }}
    />
  );
}

function renderShape(shape: Shape, key: number) {
  switch (shape.type) {
    case 'polyline': {
      const points = shape.closed ? [...shape.points, shape.points[0]] : shape.points;
      return points.slice(1).map((point, i) => (
        <Segment
          key={`${key}-${i}`}
          a={points[i]}
          b={point}
          strokeWidth={shape.strokeWidth}
          color={shape.color}
        />
      ));
    }
    case 'quadratic': {
      const points = quadraticPoints(shape.from, shape.control, shape.to);
      return points.slice(1).map((point, i) => (
        <Segment
          key={`${key}-${i}`}
          a={points[i]}
          b={point}
          strokeWidth={shape.strokeWidth}
          color={shape.color}
        />
      ));
    }
    case 'circle':
      return (
        <View
          key={key}
          style={{
            position: 'absolute',
            left: shape.center[0] - shape.radius,
            top: shape.center[1] - shape.radius,
            width: shape.radius * 2,
            height: shape.radius * 2,
            borderRadius: shape.radius,
            backgroundColor: shape.color,
          }}
        />
      );
    case 'roundRect':
      return (
        <View
          key={key}
          style={{
            position: 'absolute',
            left: shape.x - shape.strokeWidth / 2,
            top: shape.y - shape.strokeWidth / 2,
            width: shape.width + shape.strokeWidth,
            height: shape.height + shape.strokeWidth,
            borderRadius: shape.radius,
            borderWidth: shape.strokeWidth,
            borderColor: shape.color,
          }}
        />
      );
  }
}

export function PatternCanvas({ draw }: PatternCanvasProps) {
  const [size, setSize] = useState({ width: 0, height: 0 });

  return (
    <View
      pointerEvents="none"
      style={StyleSheet.absoluteFill}
      onLayout={(event) => {
        const { width, height } = event.nativeEvent.layout;
        setSize({ width, height });
      }}>
      {size.width > 0 && draw(size.width, size.height).map(renderShape)}
    </View>
  );
}
