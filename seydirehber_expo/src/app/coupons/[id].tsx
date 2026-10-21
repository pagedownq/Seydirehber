import { useLocalSearchParams } from 'expo-router';

import { CouponDetailScreen } from '@/screens/coupon-detail-screen';

export default function CouponDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  // key: başka bir kupona geçilince ekran durumu sıfırdan kurulur.
  return <CouponDetailScreen key={id} couponId={id} />;
}
