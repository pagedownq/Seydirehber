import { requireOptionalNativeModule } from 'expo';

type FlutterPrefsNative = {
  getAll(): Record<string, string | number | boolean | string[]>;
};

const FlutterPrefs = requireOptionalNativeModule<FlutterPrefsNative>('FlutterPrefs');

/**
 * Eski Flutter sürümünün shared_preferences ile bıraktığı değerler ("flutter." öneki atılmış).
 * Native modül yoksa (web, eski build) boş nesne döner.
 */
export function getFlutterPrefs(): Record<string, string | number | boolean | string[]> {
  return FlutterPrefs?.getAll() ?? {};
}
