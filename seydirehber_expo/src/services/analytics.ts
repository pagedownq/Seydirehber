import {
  getAnalytics,
  logEvent as firebaseLogEvent,
  logLogin as firebaseLogLogin,
  logScreenView as firebaseLogScreenView,
  logSearch as firebaseLogSearch,
  logSignUp as firebaseLogSignUp,
  setUserId as firebaseSetUserId,
  setUserProperty as firebaseSetUserProperty,
} from '@react-native-firebase/analytics';
import { usePathname, useSegments } from 'expo-router';
import { useEffect } from 'react';

// Flutter lib/core/services/analytics_service.dart karşılığı. Olay adları ve parametreler aynı.
const analytics = getAnalytics();

// Analytics hataları uygulamayı etkilemesin.
const safe = (result: unknown) => {
  if (result instanceof Promise) result.catch(() => {});
};

export const analyticsService = {
  logScreenView(screenName: string, screenClass?: string) {
    safe(firebaseLogScreenView(analytics, { screen_name: screenName, screen_class: screenClass ?? screenName }));
  },
  logEvent(name: string, parameters?: Record<string, string | number>) {
    safe(firebaseLogEvent(analytics, name, parameters));
  },
  logCompanyView(companyId: string, companyName: string) {
    this.logEvent('view_company', { company_id: companyId, company_name: companyName });
  },
  logPlaceView(placeId: string, placeName: string) {
    this.logEvent('view_place', { place_id: placeId, place_name: placeName });
  },
  logEventClick(eventId: string, eventTitle: string) {
    this.logEvent('click_event', { event_id: eventId, event_title: eventTitle });
  },
  logCouponView(couponId: string, couponName: string) {
    this.logEvent('view_coupon', { coupon_id: couponId, coupon_name: couponName });
  },
  logSearch(searchTerm: string) {
    safe(firebaseLogSearch(analytics, { search_term: searchTerm }));
  },
  logLogin(method: string) {
    safe(firebaseLogLogin(analytics, { method }));
  },
  logSignUp(method: string) {
    safe(firebaseLogSignUp(analytics, { method }));
  },
  setUserId(id: string | null) {
    safe(firebaseSetUserId(analytics, id));
  },
  setUserProperty(name: string, value: string) {
    safe(firebaseSetUserProperty(analytics, name, value));
  },
};

/**
 * Flutter FirebaseAnalyticsObserver karşılığı: her ekran değişiminde screen_view.
 * Ekran adı go_router'daki gibi yol kalıbıdır (`/events/:id`); gruplar (`(tabs)`) atlanır.
 */
export function useScreenTracking() {
  const pathname = usePathname();
  const segments = useSegments();

  useEffect(() => {
    const name =
      '/' +
      segments
        .filter((segment) => !segment.startsWith('('))
        .map((segment) => segment.replace(/^\[(.+)\]$/, ':$1'))
        .join('/');
    analyticsService.logScreenView(name);
    // segments her çizimde yeni dizi; sadece yol değişince kaydedilir.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pathname]);
}
