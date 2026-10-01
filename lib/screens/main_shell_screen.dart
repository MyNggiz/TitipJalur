import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/interactive_bottom_nav.dart';
import 'account_settings_screen.dart';
import 'dashboard_screen.dart';
import 'errand_orders_page.dart';
import 'homepage_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavigateTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomepageScreen(
        onExploreFeed: () => _onNavigateTab(1),
      ),
      const DashboardScreen(isEmbedded: true),
      const ErrandOrdersPage(),
      const AccountSettingsScreen(),
    ];

    final navItems = const [
      NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      NavItem(
        icon: Icons.radar_outlined,
        activeIcon: Icons.radar_rounded,
        label: 'Feed Rute',
      ),
      NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Titipan',
      ),
      NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Akun',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: InteractiveBottomNav(
              currentIndex: _currentIndex,
              onTap: _onNavigateTab,
              items: navItems,
            ),
          ),
        ),
      ),
    );
  }
}
