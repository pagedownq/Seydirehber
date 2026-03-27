import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/places/screens/place_detail_screen.dart';
import '../../features/companies/screens/company_detail_screen.dart';
import '../../features/services/screens/pharmacy_screen.dart';
import '../../features/services/screens/noterler_screen.dart';
import '../../features/services/screens/pazarlar_screen.dart';
import '../../features/services/screens/otobus_screen.dart';
import '../../features/services/screens/weather_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/settings/screens/policies_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/admin/screens/admin_manage_screen.dart';
import '../widgets/generic_list_screen.dart';
import '../../features/home/providers/home_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = docsCompletedCheck(prefs);

      if (!onboardingCompleted && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main Shell (Home, News, Settings)
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),

      // Help & Support
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),

      // Search
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return SearchScreen(initialQuery: query);
        },
      ),

      // Policies
      GoRoute(
        path: '/policies',
        builder: (context, state) => const PoliciesScreen(),
      ),

      // Events
      GoRoute(
        path: '/events',
        builder: (context, state) => GenericListScreen(
          title: 'Etkinlikler',
          provider: allEventsProvider,
          routePrefix: 'events',
        ),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),

      // Places
      GoRoute(
        path: '/places',
        builder: (context, state) => GenericListScreen(
          title: 'Gezilecek Yerler',
          provider: allPlacesProvider,
          routePrefix: 'places',
        ),
      ),
      GoRoute(
        path: '/places/:id',
        builder: (context, state) => PlaceDetailScreen(
          placeId: state.pathParameters['id']!,
        ),
      ),

      // Companies
      GoRoute(
        path: '/companies',
        builder: (context, state) => GenericListScreen(
          title: 'Firmalar',
          provider: allCompaniesProvider,
          routePrefix: 'companies',
          showViewCount: true,
        ),
      ),
      GoRoute(
        path: '/companies/:id',
        builder: (context, state) => CompanyDetailScreen(
          companyId: state.pathParameters['id']!,
        ),
      ),

      // Services
      GoRoute(
        path: '/pharmacy',
        builder: (context, state) => const PharmacyScreen(),
      ),
      GoRoute(
        path: '/noterler',
        builder: (context, state) => const NoterlerScreen(),
      ),
      GoRoute(
        path: '/pazarlar',
        builder: (context, state) => const PazarlarScreen(),
      ),
      GoRoute(
        path: '/otobus',
        builder: (context, state) => const OtobusScreen(),
      ),
      GoRoute(
        path: '/weather',
        builder: (context, state) => const WeatherScreen(),
      ),

      // News standalone route
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsScreen(),
      ),

      // Admin
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/admin/manage',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AdminManageScreen(
            collection: extra['collection'] as String? ?? '',
            title: extra['title'] as String? ?? '',
            bucket: extra['bucket'] as String?,
          );
        },
      ),
    ],
  );
});

bool docsCompletedCheck(SharedPreferences prefs) {
  return prefs.getBool('onboarding_completed') ?? false;
}
