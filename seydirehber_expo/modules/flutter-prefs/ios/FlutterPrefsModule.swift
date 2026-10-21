import ExpoModulesCore

// Flutter shared_preferences iOS'ta değerleri NSUserDefaults.standard içinde "flutter." önekiyle tutar.
public class FlutterPrefsModule: Module {
  private let prefix = "flutter."

  public func definition() -> ModuleDefinition {
    Name("FlutterPrefs")

    Function("getAll") { () -> [String: Any] in
      var result: [String: Any] = [:]
      for (key, value) in UserDefaults.standard.dictionaryRepresentation() where key.hasPrefix(self.prefix) {
        let name = String(key.dropFirst(self.prefix.count))
        if let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() {
          result[name] = number.boolValue
        } else if value is String || value is NSNumber || value is [String] {
          result[name] = value
        }
      }
      return result
    }
  }
}
