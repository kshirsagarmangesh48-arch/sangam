import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  static const String _storageKey = 'selected_language_code';

  // Default to system, fallback to English
  final Rx<Locale> _locale = const Locale('en').obs;
  Locale get locale => _locale.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_storageKey);

    if (savedCode != null) {
      _locale.value = Locale(savedCode);
    } else {
      // Logic to perhaps check device locale or default
      _locale.value = const Locale('en');
    }
  }

  Future<void> changeLanguage(Locale newLocale) async {
    if (newLocale == _locale.value) return;

    _locale.value = newLocale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, newLocale.languageCode);

    // Get.updateLocale(newLocale) is for GetMaterialApp functionality usually,
    // but we are binding locale in main.dart to this controller.
  }
}
