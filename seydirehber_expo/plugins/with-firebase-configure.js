// Expo SDK 58 iOS şablonu (58.0.23+) React Native'i SceneDelegate'te başlatıyor; AppDelegate.swift'te
// `factory.startReactNative(` satırı yok. @react-native-firebase/app plugin'i FirebaseApp.configure()'u
// bu satırın üstüne eklemeye çalışıyor, bulamayınca sadece uyarı verip eklemiyor → native Firebase hiç
// başlatılmıyor ve production'da açılışta "No Firebase App '[DEFAULT]' has been created" ile çöküyor
// (1.0.11 build 34–36). Bu plugin satırı super.application(...) çağrısından önce ekler; satır zaten
// varsa (RNFirebase plugin'i ileride düzelirse) dokunmaz.
const { withAppDelegate, WarningAggregator } = require('expo/config-plugins');

const CONFIGURE = 'FirebaseApp.configure()';
const SUPER_CALL = /^([ \t]*)return super\.application\(\s*application,\s*didFinishLaunchingWithOptions/m;

function addFirebaseConfigure(contents) {
  if (contents.includes(CONFIGURE)) return contents;

  const match = SUPER_CALL.exec(contents);
  if (!match) {
    WarningAggregator.addWarningIOS(
      'with-firebase-configure',
      'AppDelegate.swift içinde super.application(... didFinishLaunchingWithOptions) bulunamadı; FirebaseApp.configure() eklenmedi.',
    );
    return contents;
  }
  const indent = match[1];
  contents = `${contents.slice(0, match.index)}${indent}${CONFIGURE}\n${contents.slice(match.index)}`;

  if (!/^[ \t]*import\s+FirebaseCore[ \t]*$/m.test(contents)) {
    contents = `import FirebaseCore\n${contents}`;
  }
  return contents;
}

module.exports = function withFirebaseConfigure(config) {
  return withAppDelegate(config, (config) => {
    if (config.modResults.language !== 'swift') return config;
    config.modResults.contents = addFirebaseConfigure(config.modResults.contents);
    return config;
  });
};

module.exports.addFirebaseConfigure = addFirebaseConfigure;
