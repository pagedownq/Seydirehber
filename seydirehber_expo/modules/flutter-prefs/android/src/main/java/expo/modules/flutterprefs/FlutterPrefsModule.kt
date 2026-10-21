package expo.modules.flutterprefs

import android.content.Context
import android.util.Base64
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import org.json.JSONArray
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream

// Flutter shared_preferences (legacy API) Android'de "FlutterSharedPreferences" dosyasında,
// "flutter." önekiyle tutar. Liste ve double değerler özel öneklerle string olarak saklanır.
class FlutterPrefsModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("FlutterPrefs")

    Function("getAll") {
      val context = appContext.reactContext ?: return@Function emptyMap<String, Any>()
      val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      val result = mutableMapOf<String, Any>()
      for ((key, value) in prefs.all) {
        if (!key.startsWith(KEY_PREFIX) || value == null) continue
        val decoded = decode(value) ?: continue
        result[key.removePrefix(KEY_PREFIX)] = decoded
      }
      result
    }
  }

  private fun decode(value: Any): Any? {
    if (value !is String) return value
    return try {
      when {
        value.startsWith(JSON_LIST_PREFIX) -> {
          val array = JSONArray(value.removePrefix(JSON_LIST_PREFIX))
          List(array.length()) { array.getString(it) }
        }
        value.startsWith(LIST_PREFIX) -> {
          val bytes = Base64.decode(value.removePrefix(LIST_PREFIX), 0)
          ObjectInputStream(ByteArrayInputStream(bytes)).use { stream ->
            (stream.readObject() as List<*>).map { it.toString() }
          }
        }
        value.startsWith(DOUBLE_PREFIX) -> value.removePrefix(DOUBLE_PREFIX).toDouble()
        value.startsWith(BIG_INTEGER_PREFIX) -> value.removePrefix(BIG_INTEGER_PREFIX).toDouble()
        else -> value
      }
    } catch (e: Exception) {
      null
    }
  }

  companion object {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_PREFIX = "flutter."
    private const val LIST_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu"
    private const val JSON_LIST_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!"
    private const val BIG_INTEGER_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy"
    private const val DOUBLE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu"
  }
}
