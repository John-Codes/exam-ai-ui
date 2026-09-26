import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's own OpenRouter API key in the browser only.
///
/// The key is sent to the exam API per-request via the `X-OpenRouter-Key`
/// header and is never shown in chat, never typed into a message, and never
/// persisted on any server. Cleaning it up is a single [OpenRouterKeyStore.clear].
class OpenRouterKeyStore {
  static const _kKey = 'testready.openrouter_key';
  static const _kMasked = 'testready.openrouter_key_has';

  /// Returns the stored key, or null when the user hasn't set one.
  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kKey);
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  /// Whether the user has set their own key (without exposing its value).
  static Future<bool> has() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kMasked) == true;
  }

  static Future<void> set(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final v = value.trim();
    if (v.isEmpty) {
      await prefs.remove(_kKey);
      await prefs.remove(_kMasked);
    } else {
      await prefs.setString(_kKey, v);
      await prefs.setBool(_kMasked, true);
    }
  }

  static Future<void> clear() => set('');
}