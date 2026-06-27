import 'package:flutter/material.dart';
import 'package:dog_friendly_map/screens/main_map_screen.dart';
import 'package:dog_friendly_map/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final String currentLang;
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;

  const MainNavigation({
    super.key,
    required this.currentThemeMode,
    required this.currentLang,
    required this.onThemeToggle,
    required this.onLanguageToggle,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final PageController _pageController = PageController(initialPage: 0);

  void _goToProfile() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToMap() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          MainMapScreen(
            currentThemeMode: widget.currentThemeMode,
            currentLang: widget.currentLang,
            onThemeToggle: widget.onThemeToggle,
            onLanguageToggle: widget.onLanguageToggle,
            onOpenProfile: _goToProfile,
          ),
          ProfileScreen(
            currentLang: widget.currentLang,
            onBackToMap: _goToMap,
          ),
        ],
      ),
    );
  }
}