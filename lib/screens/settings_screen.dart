import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final String currentLang;
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;

  const SettingsScreen({
    super.key,
    required this.currentThemeMode,
    required this.currentLang,
    required this.onThemeToggle,
    required this.onLanguageToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = currentThemeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLang == 'en' ? 'Settings' : currentLang == 'ua' ? 'Налаштування' : 'Настройки'),
        backgroundColor: isDark ? Colors.grey[850] : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.green),
            title: Text(currentLang == 'en' ? 'Dark Mode' : currentLang == 'ua' ? 'Темна тема' : 'Темная тема'),
            trailing: Switch(
              value: isDark,
              onChanged: (bool value) {
                onThemeToggle();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.green),
            title: Text(currentLang == 'en' ? 'Language' : currentLang == 'ua' ? 'Мова' : 'Язык'),
            trailing: ElevatedButton(
              onPressed: onLanguageToggle,
              child: Text(currentLang.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}