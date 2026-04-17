import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MapHelper {
  /// Launches external map application for directions
  static Future<void> openOnMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Converts various location formats (URLs, text addresses, coordinates, DMS) to LatLng
  static Future<LatLng?> getCoordinates(String locationData) async {
    if (locationData.isEmpty) return null;

    try {
      // 1. Try to parse Google Maps URL
      final urlRegExp = RegExp(r'(!3d|!4d|@|ll=)(-?\d+\.\d+),(-?\d+\.\d+)');
      final match = urlRegExp.firstMatch(locationData);
      if (match != null) {
        final lat = double.tryParse(match.group(2)!);
        final lng = double.tryParse(match.group(3)!);
        if (lat != null && lng != null) return LatLng(lat, lng);
      }

      // 2. Try to parse DMS (36°46'52.9"N 31°26'39.0"E)
      final dmsRegExp = RegExp(
          r'(\d+)°(\d+)\x27([\d.]+)"([NSEW])\s+(\d+)°(\d+)\x27([\d.]+)"([NSEW])',
          caseSensitive: false);
      final dmsMatch = dmsRegExp.firstMatch(locationData);
      if (dmsMatch != null) {
        double lat = _convertDMSToDecimal(
          degrees: double.parse(dmsMatch.group(1)!),
          minutes: double.parse(dmsMatch.group(2)!),
          seconds: double.parse(dmsMatch.group(3)!),
          direction: dmsMatch.group(4)!,
        );
        double lng = _convertDMSToDecimal(
          degrees: double.parse(dmsMatch.group(5)!),
          minutes: double.parse(dmsMatch.group(6)!),
          seconds: double.parse(dmsMatch.group(7)!),
          direction: dmsMatch.group(8)!,
        );
        return LatLng(lat, lng);
      }

      // 3. Try plain "lat, lng"
      final plainCoordExp = RegExp(r'^(-?\d+\.\d+),\s*(-?\d+\.\d+)$');
      final plainMatch = plainCoordExp.firstMatch(locationData.trim());
      if (plainMatch != null) {
        final lat = double.tryParse(plainMatch.group(1)!);
        final lng = double.tryParse(plainMatch.group(2)!);
        if (lat != null && lng != null) return LatLng(lat, lng);
      }

      // 4. Treat as a text address (Geocoding)
      List<Location> locations = await locationFromAddress(locationData);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print('Location Parsing Error: $e');
    }
    return null;
  }

  /// NEW METHOD: Converts any location data (Link, GPS, DMS) to a readable address
  static Future<String> getReadableAddress(String locationData) async {
    if (locationData.isEmpty) return 'Adres belirtilmemiş';

    // If it's already a clean address (like starting with Hisar...), return it directly to save API calls
    // (Assuming addresses don't start with numbers or http or typical DMS chars)
    if (!locationData.contains('http') && 
        !locationData.contains('°') && 
        !RegExp(r'^-?\d+\.').hasMatch(locationData.trim())) {
      return locationData;
    }

    try {
      final coords = await getCoordinates(locationData);
      if (coords != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          coords.latitude, 
          coords.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Example: "Aşağı Hisar, Orhan Gazi Cd. No:54, 07600 Manavgat/Antalya"
          String street = p.thoroughfare ?? p.name ?? '';
          String subLocality = p.subLocality ?? p.locality ?? '';
          String city = p.administrativeArea ?? '';
          
          return "$subLocality, $street CP: ${p.postalCode}, $city".replaceAll(', ,', ',');
        }
      }
    } catch (e) {
      print('Reverse Geocoding Error: $e');
    }
    
    return locationData; // Fallback to raw data if parsing fails
  }

  static double _convertDMSToDecimal({
    required double degrees,
    required double minutes,
    required double seconds,
    required String direction,
  }) {
    double decimal = degrees + (minutes / 60) + (seconds / 3600);
    if (direction.toUpperCase() == 'S' || direction.toUpperCase() == 'W') {
      decimal = decimal * -1;
    }
    return decimal;
  }
}
