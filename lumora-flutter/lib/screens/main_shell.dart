import 'package:flutter/material.dart';
import 'package:lumora_flutter/screens/anochat_screen.dart';
import 'package:lumora_flutter/screens/home_screen.dart';
import 'package:lumora_flutter/screens/partner_screen.dart';

import 'package:lumora_flutter/screens/readmore_screen.dart';
import 'package:lumora_flutter/screens/profile_screen.dart';
import 'package:lumora_flutter/widgets/lumora_nav_bar.dart';

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
          const ReadMoreScreen(),
          // 2 – AnonChat
          const AnoChatScreen(),
          // 3 – Partner
          const PartnerScreen(),
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
