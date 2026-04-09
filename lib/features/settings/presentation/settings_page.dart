import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sangam/features/auth/controllers/auth_controller.dart';
import 'package:sangam/features/settings/controllers/language_controller.dart';
import 'package:sangam/features/settings/controllers/theme_controller.dart';
import 'package:sangam/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    
    final userEmail = authController.firebaseUser.value?.email ?? 'Unknown Email';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
             elevation: 2,
             child: ListTile(
               leading: const Icon(Icons.person),
               title: const Text('Email'),
               subtitle: Text(userEmail),
             ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.settings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.language),
              trailing: Obx(() {
                final locale = languageController.locale;
                return DropdownButton<String>(
                  value: locale.languageCode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      languageController.changeLanguage(Locale(value));
                    }
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Obx(() {
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                value: themeController.isDarkMode,
                onChanged: (value) {
                  themeController.toggleTheme(value);
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Show a confirmation dialog or just logout
                authController.logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}
