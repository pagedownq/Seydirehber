// expo-notifications ve @react-native-firebase/messaging aynı FCM meta-data anahtarlarını
// manifest'e ekliyor; birleştirme çakışmasın diye uygulamanın değerleri geçerli sayılır.
const { withAndroidManifest } = require('expo/config-plugins');

const REPLACE_ATTRIBUTES = {
  'com.google.firebase.messaging.default_notification_channel_id': 'android:value',
  'com.google.firebase.messaging.default_notification_color': 'android:resource',
  'com.google.firebase.messaging.default_notification_icon': 'android:resource',
};

module.exports = function withFcmManifestFix(config) {
  return withAndroidManifest(config, (config) => {
    const manifest = config.modResults.manifest;
    manifest.$['xmlns:tools'] = 'http://schemas.android.com/tools';

    const application = manifest.application?.[0];
    for (const item of application?.['meta-data'] ?? []) {
      const attribute = REPLACE_ATTRIBUTES[item.$['android:name']];
      if (attribute) item.$['tools:replace'] = attribute;
    }
    return config;
  });
};
