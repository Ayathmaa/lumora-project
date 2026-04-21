import 'package:flutter/material.dart';
import 'package:lumora_flutter/screens/anochat_screen.dart';
import 'package:lumora_flutter/screens/home_screen.dart';

import 'package:lumora_flutter/screens/readmore_screen.dart';
import 'package:lumora_flutter/screens/profile_screen.dart';
import 'package:lumora_flutter/widgets/lumora_nav_bar.dart';

// ── Placeholder screens for tabs not yet built ───────────────────────────
class _ComingSoonScreen extends StatelessWidget {
  final String title;
  const _ComingSoonScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC8DCF0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction_rounded,
              size: 64,
              color: Color(0xFF6BAED4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A3A5C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon…',
              style: TextStyle(fontSize: 14, color: Color(0xFF4A6FA5)),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────

/// The top-level shell that owns the nav bar and switches between tabs.
/// ALL screens inside this shell share a single [LumoraNavBar] instance.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;

  void _switchTab(int index) => setState(() => _navIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No background here — each tab screen sets its own scaffold colour.
      body: IndexedStack(
        index: _navIndex,
        children: [
          // 0 – Home
          HomeScreen(onProfileTap: () => _switchTab(4)),
          // 1 – ReadMore
          ReadMoreScreen(onBack: () => _switchTab(0)),
          // 2 – AnonChat
          const AnoChatScreen(),
          // 3 – Partner
          const _ComingSoonScreen(title: 'Partner'),
          // 4 – Profile
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: LumoraNavBar(
        currentIndex: _navIndex,
        onTap: _switchTab,
      ),
    );
  }
}
