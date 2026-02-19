import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sangam/core/theme/app_theme.dart';
import 'package:sangam/features/auth/controllers/auth_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sangam/l10n/app_localizations.dart';
import 'package:sangam/features/settings/controllers/language_controller.dart';
import 'package:sangam/firebase_options.dart';
import 'package:sangam/core/constants/global_keys.dart';
import 'package:sangam/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Controllers (Dependency Injection)
  Get.put(AuthController());
  Get.put(LanguageController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    return Obx(() {
      return MaterialApp.router(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: 'Sangam',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        locale: languageController.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('mr'), // Marathi
        ],
      );
    });
  }
}
