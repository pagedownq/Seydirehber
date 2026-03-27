class AppAssets {
  AppAssets._();

  // Base paths
  static const String _assetsPath = 'assets/';

  // Logos & Icons
  static const String appLogo = '${_assetsPath}SeydiRehber.png';
  static const String eczaneLogo = '${_assetsPath}eczane_logo.png';
  static const String noterImage = '${_assetsPath}noter.png';
  static const String otobusImage = '${_assetsPath}otobus.jpg';
  static const String pazarImage = '${_assetsPath}pazar.jpg';
  static const String pazarPazariImage = '${_assetsPath}pazarpazari.jpeg';
  static const String persembePazariImage = '${_assetsPath}persembepazari.jpeg';
  static const String seydisehirNoterImage = '${_assetsPath}seydisehir-noter.webp';

  // Supabase Storage Buckets
  static const String bucketBanner = 'banner';
  static const String bucketEtkinlikler = 'etkinlikler';
  static const String bucketNoter = 'noter';
  static const String bucketPazar = 'pazar';
  static const String bucketGezilcekYerler = 'gezilcek_yerler';
  static const String bucketFirmalar = 'firmalar';

  // URLs
  static const String weatherUrl =
      'https://weather-screen.web-apps-prod.wo-cloud.com/v2/screen/?locale=tr-TR&name=Seydi%C5%9Fehir&geoObjectKey=11636345&airPressureUnit=hpa&temperatureUnit=celsius&windUnit=kmh&systemOfMeasurement=metric&timeFormat=HH%3Amm';
  static const String pharmacyUrl =
      'https://enyakineczane.com.tr/iframe/?city=42&district=1617&zoom=1';
  static const String toroslarGazetesiRss =
      'https://www.toroslargazetesi.com.tr/rss';
}
