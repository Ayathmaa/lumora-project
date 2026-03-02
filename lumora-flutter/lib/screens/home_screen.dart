import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/screens/login_screen.dart';
import 'package:lumora_flutter/widgets/lumora_nav_bar.dart';
import 'package:lumora_flutter/screens/journal_screen.dart';
import 'package:lumora_flutter/screens/erp_timer_screen.dart';
import 'package:lumora_flutter/screens/progress_screen.dart';
import 'package:lumora_flutter/screens/mindful_screen.dart';

// ── colour palette ──────────────────────────────────────────────────────────
const _kBg = Color(0xFFC8DCF0); // scaffold background
const _kNavy = Color(0xFF1A3A5C); // headings / bold text
const _kSubtitle = Color(0xFF4A6FA5); // subtitle text
const _kGreetingCard = Color(0xFFBDD9EF); // greeting card bg
const _kCardBg = Colors.white; // white card bg
const _kIconBg = Color(0xFFD6ECFA); // icon container bg
const _kBlue = Color(0xFF6BAED4); // buttons / accent text
const _kEmojiCircle = Color(0xFFE0F0FA); // mood emoji circle bg
const _kBarTrack = Color(0xFFE0EAF4); // XP bar track
// ────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  int _navIndex = 0;
  int? _selectedMood; // 0 = saddest … 4 = happiest

  // ── logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName =
        (user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Aurora')
            .toUpperCase();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── greeting card ─────────────────────────────────────────────
              _GreetingCard(name: displayName, onLogout: _logout),
              const SizedBox(height: 14),

              // ── quote of the day ──────────────────────────────────────────
              const _QuoteCard(),
              const SizedBox(height: 14),

              // ── daily mood log ────────────────────────────────────────────
              _MoodCard(
                selectedMood: _selectedMood,
                onMoodSelected: (i) => setState(() => _selectedMood = i),
              ),
              const SizedBox(height: 14),

              // ── feature grid ──────────────────────────────────────────────
              const _FeatureGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: LumoraNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Greeting Card
// ════════════════════════════════════════════════════════════════════════════
class _GreetingCard extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;

  const _GreetingCard({required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kGreetingCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row + logout icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'HI, $name ',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: _kNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const TextSpan(
                        text: '💜',
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: _kSubtitle,
                  size: 20,
                ),
                onPressed: onLogout,
                tooltip: 'Logout',
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Level label
          const Text(
            'Level 3 – Blooming Soul',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 10),

          // XP progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.32,
              minHeight: 10,
              backgroundColor: _kBarTrack,
              valueColor: AlwaysStoppedAnimation<Color>(_kNavy),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Quote of the Day Card
// ════════════════════════════════════════════════════════════════════════════
class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote of the day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kNavy,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '"You are growing gently, one day at a time."',
            style: TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _kSubtitle,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Daily Mood Log Card
// ════════════════════════════════════════════════════════════════════════════
class _MoodCard extends StatelessWidget {
  final int? selectedMood;
  final ValueChanged<int> onMoodSelected;

  const _MoodCard({required this.selectedMood, required this.onMoodSelected});

  static const _moods = ['😢', '😔', '😐', '🙂', '😊'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        children: [
          // Title
          const Text(
            'Daily Mood Log',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 16),

          // Emoji row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_moods.length, (i) {
              final isSelected = selectedMood == i;
              return GestureDetector(
                onTap: () => onMoodSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected
                            ? _kBlue.withValues(alpha: 0.25)
                            : _kEmojiCircle,
                    border:
                        isSelected ? Border.all(color: _kBlue, width: 2) : null,
                  ),
                  child: Center(
                    child: Text(
                      _moods[i],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Add Note button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Add Note',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Feature Grid  (2 × 2)
// ════════════════════════════════════════════════════════════════════════════
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const _features = [
    _Feature(icon: Icons.menu_book_rounded, label: 'Journal'),
    _Feature(icon: Icons.timer_rounded, label: 'ERP Timer'),
    _Feature(icon: Icons.bar_chart_rounded, label: 'Progress'),
    _Feature(icon: Icons.eco_rounded, label: 'Mindful'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.05,
      children: _features.map((f) => _FeatureCard(feature: f)).toList(),
    );
  }
}

Widget _routeForFeature(String label) {
  switch (label) {
    case 'Journal':   return const JournalScreen();
    case 'ERP Timer': return const ErpTimerScreen();
    case 'Progress':  return const ProgressScreen();
    case 'Mindful':   return const MindfulScreen();
    default:          return const SizedBox();
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _routeForFeature(feature.label)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: _kIconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(feature.icon, size: 32, color: _kBlue),
            ),
            const SizedBox(height: 12),
            Text(
              feature.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});
}
