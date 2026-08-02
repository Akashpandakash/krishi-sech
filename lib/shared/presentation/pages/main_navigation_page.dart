import 'package:flutter/material.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:krishi_sech/features/home/presentation/pages/home_page.dart';
import 'package:krishi_sech/features/market/presentation/pages/market_page.dart';
import 'package:krishi_sech/features/my_crop/presentation/pages/my_crop_page.dart';
import 'package:krishi_sech/features/profile/presentation/pages/profile_page.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  static const _pages = [
    HomePage(),
    MyCropPage(),
    AiAssistantPage(),
    MarketPage(),
    ProfilePage(),
  ];

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.eco_outlined),
            selectedIcon: const Icon(Icons.eco),
            label: context.l10n.navMyCrops,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: context.l10n.navAiAssistant,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: context.l10n.navMarket,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
