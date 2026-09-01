import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _apiKeyKey = 'gemini_api_key';
  static const _nativeLangKey = 'native_language_code';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key.trim());
  }

  Future<String> getNativeLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nativeLangKey) ?? 'en';
  }

  Future<void> saveNativeLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nativeLangKey, code);
  }
}
