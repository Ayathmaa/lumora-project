import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/services/mood_service.dart';
import 'package:lumora_flutter/services/quote_service.dart';
import 'package:lumora_flutter/services/gamification_service.dart';
import 'package:lumora_flutter/services/gamification_utils.dart';
import 'package:lumora_flutter/services/insights_service.dart';

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
  final VoidCallback? onProfileTap;
  const HomeScreen({super.key, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _authService = AuthService();
  final _moodService = MoodService();

  int? _selectedMood; // 0 = saddest … 4 = happiest
  String? _anonUsername;
  bool _isMoodVisible = false;
  bool _isMoodSaved = false;
  bool _isMoodSaving = false;
  Timer? _moodTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initMoodVisibility();
    _checkTodayMood();

    final user = _authService.currentUser;
    if (user != null && user.isAnonymous) {
      if (user.displayName?.isNotEmpty == true) {
        // Already cached in Firebase Auth — no Firestore round-trip needed.
        _anonUsername = user.displayName;
      } else {
        // Older guest accounts: fetch from Firestore then cache in Auth.
        _authService
            .getUsername(user.uid)
            .then((name) async {
              if (!mounted || name == null) return;
              setState(() => _anonUsername = name);
              // Patch displayName so future launches are instant.
              try {
                await user.updateDisplayName(name);
              } catch (_) {}
            })
            .catchError((e) {
              debugPrint('HomeScreen: could not load guest username – $e');
            });
      }
    }
  }

  void _initMoodVisibility() {
    final now = DateTime.now();
    // Show mood card from 7 PM onwards.
    if (now.hour >= 19) {
      _isMoodVisible = true;
    } else {
      // Schedule the card to appear at exactly 19:00 today.
      final target = DateTime(now.year, now.month, now.day, 19, 0, 0);
      _moodTimer = Timer(target.difference(now), () {
        if (mounted) setState(() => _isMoodVisible = true);
      });
    }
  }

  void _checkTodayMood() {
    _moodService
        .hasTodayMood()
        .then((saved) {
          if (mounted) setState(() => _isMoodSaved = saved);
        })
        .catchError((_) {});
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null || _isMoodSaving) return;
    setState(() => _isMoodSaving = true);
    try {
      await _moodService.saveTodayMood(score: _selectedMood! + 1);
      if (!mounted) return;
      setState(() {
        _isMoodSaved = true;
        _isMoodSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMoodSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save mood: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _moodTimer?.cancel();
    super.dispose();
  }

  // Re-check mood state when the user returns to the app (e.g. after logging
  // mood via the notification action while the app was in the background).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isMoodSaved) {
      _checkTodayMood();
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final String displayName;
    if (user != null && user.isAnonymous) {
      displayName = (_anonUsername ?? '...').toUpperCase();
    } else {
      displayName =
          (user?.displayName?.isNotEmpty == true
                  ? user!.displayName!
                  : 'Aurora')
              .toUpperCase();
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── greeting card ─────────────────────────────────────────────
              _GreetingCard(
                name: displayName,
                photoUrl: user?.photoURL,
                onProfileTap: widget.onProfileTap,
              ),
              const SizedBox(height: 14),

              // ── quote of the day ──────────────────────────────────────────
              const _QuoteCard(),
              const SizedBox(height: 14),

              // ── insights ──────────────────────────────────────────────────
              const _InsightsCard(),
              const SizedBox(height: 14),

              // ── daily mood log (visible from 7 PM) ───────────────────────
              if (_isMoodVisible) ...[
                _MoodCard(
                  selectedMood: _selectedMood,
                  onMoodSelected: (i) => setState(() => _selectedMood = i),
                  isSaved: _isMoodSaved,
                  isSaving: _isMoodSaving,
                  onSave: _saveMood,
                ),
                const SizedBox(height: 14),
              ],

              // ── feature grid ──────────────────────────────────────────────
              const _FeatureGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Greeting Card
// ════════════════════════════════════════════════════════════════════════════
class _GreetingCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback? onProfileTap;

  const _GreetingCard({
    required this.name,
    this.photoUrl,
    required this.onProfileTap,
  });

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
          // Name row + profile icon
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
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    shape: BoxShape.circle,
                    image:
                        photoUrl != null
                            ? DecorationImage(
                              image: NetworkImage(photoUrl!),
                              fit: BoxFit.cover,
                            )
                            : null,
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 6),
                    ],
                  ),
                  child:
                      photoUrl == null
                          ? const Icon(
                            Icons.person_rounded,
                            color: _kBlue,
                            size: 20,
                          )
                          : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Level & XP Stream
          StreamBuilder<GamificationStats>(
            stream: GamificationService().getStatsStream(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? const GamificationStats();
              final levelDisplay = GamificationUtils.getLevelDisplay(stats.xp);
              final progress = GamificationUtils.getProgress(stats.xp);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    levelDisplay,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: _kBarTrack,
                      valueColor: const AlwaysStoppedAnimation<Color>(_kNavy),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Quote of the Day Card
// ════════════════════════════════════════════════════════════════════════════
class _QuoteCard extends StatefulWidget {
  const _QuoteCard();

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard> {
  final _service = QuoteService();
  DailyQuote? _quote;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final quote = await _service.fetchTodayQuote();
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quote of the day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kBlue,
                  ),
                ),
              ),
            )
          else if (_hasError || _quote == null)
            const Text(
              '"You are growing gently, one day at a time."',
              style: TextStyle(
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _kSubtitle,
                height: 1.4,
              ),
            )
          else ...[
            Text(
              '\u201c${_quote!.text}\u201d',
              style: const TextStyle(
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _kSubtitle,
                height: 1.5,
              ),
            ),
            if (_quote!.author.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '\u2014 ${_quote!.author}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kBlue,
                ),
              ),
            ],
          ],
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
  final bool isSaved;
  final bool isSaving;
  final VoidCallback onSave;

  const _MoodCard({
    required this.selectedMood,
    required this.onMoodSelected,
    required this.isSaved,
    required this.isSaving,
    required this.onSave,
  });

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
      child: isSaved ? _buildSavedState() : _buildInputState(context),
    );
  }

  Widget _buildSavedState() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF3DAA6E),
          size: 40,
        ),
        const SizedBox(height: 10),
        const Text(
          'Mood logged for today!',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kNavy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'See you tomorrow 🌙',
          style: TextStyle(fontSize: 13, color: _kSubtitle),
        ),
      ],
    );
  }

  Widget _buildInputState(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Daily Mood Log',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kNavy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'How was your day overall?',
          style: TextStyle(fontSize: 12, color: _kSubtitle),
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
                  child: Text(_moods[i], style: const TextStyle(fontSize: 24)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: selectedMood != null && !isSaving ? onSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              disabledBackgroundColor: _kBlue.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child:
                isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Log Today\'s Mood',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ],
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
    case 'Journal':
      return const JournalScreen();
    case 'ERP Timer':
      return const ErpTimerScreen();
    case 'Progress':
      return const ProgressScreen();
    case 'Mindful':
      return const MindfulScreen();
    default:
      return const SizedBox();
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
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

// ════════════════════════════════════════════════════════════════════════════
//  Insights Card
// ════════════════════════════════════════════════════════════════════════════
class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context) {
    final service = InsightsService();

    return StreamBuilder<List<Insight>>(
      stream: service.getInsightsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
            ),
          );
        }

        final insightsList = snapshot.data;
        if (insightsList == null || insightsList.isEmpty)
          return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Your Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
            ),
            ...insightsList.map((insight) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: insight.bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(insight.icon, color: insight.color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight.text,
                        style: TextStyle(
                          color: insight.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
