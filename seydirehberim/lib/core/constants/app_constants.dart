class AppConstants {
  static const String googlePlayLink = 'https://play.google.com/store/apps/details?id=com.mgverse.seydirehberim';
  static const String appStoreLink = 'https://apps.apple.com/tr/app/seydi-rehber/id6762803524';
  
  static const String shareAppLinks = '\n\n📱 Android (Google Play):\n$googlePlayLink\n\n🍏 iOS (App Store):\n$appStoreLink';

  static String getShareText(String message) {
    return '$message$shareAppLinks';
  }
}
