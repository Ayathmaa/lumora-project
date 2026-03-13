import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/services/quote_service.dart';
import 'package:lumora_flutter/screens/journal_screen.dart';
import 'package:lumora_flutter/screens/erp_timer_screen.dart';
import 'package:lumora_flutter/screens/progress_screen.dart';
import 'package:lumora_flutter/screens/mindful_screen.dart';

class NewHomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const NewHomeScreen({super.key, this.onProfileTap});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final _authService = AuthService();
  String? _anonUsername;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() {
    final user = _authService.currentUser;
    if (user != null && user.isAnonymous) {
      if (user.displayName?.isNotEmpty == true) {
        _anonUsername = user.displayName;
      } else {
        _authService
            .getUsername(user.uid)
            .then((name) {
              if (!mounted || name == null) return;
              setState(() => _anonUsername = name);
            })
            .catchError((_) {});
      }
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'GOOD MORNING';
    if (h < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final String displayName;
    if (user != null && user.isAnonymous) {
      displayName = _anonUsername ?? '...';
    } else {
      displayName =
          user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Aurora';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFC8DCF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GreetingCard(
                name: displayName,
                greeting: _greeting(),
                onProfileTap: widget.onProfileTap,
              ),
              const SizedBox(height: 16),
              const _QuoteCard(),
              const SizedBox(height: 16),
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
  final String greeting;
  final VoidCallback? onProfileTap;

  const _GreetingCard({
    required this.name,
    required this.greeting,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting text + avatar row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A6FA5),
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A3A5C),
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('✨', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD8CEFF),
                      width: 3,
                    ),
                    color: const Color(0xFFECE8FF),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: Color(0xFF8B6BC8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Inner level/progress card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFDDEEF8),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text(
                      'BLOOMING SOUL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A3A5C),
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '45%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A6FA5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Level 3',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A6FA5),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 0.45,
                    minHeight: 8,
                    backgroundColor: Color(0xFFBDD9EF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1A3A5C),
                    ),
                  ),
                ),
              ],
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
class _QuoteCard extends StatefulWidget {
  const _QuoteCard();

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard> {
  final _service = QuoteService();
  DailyQuote? _quote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final q = await _service.fetchTodayQuote();
      if (!mounted) return;
      setState(() {
        _quote = q;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: const [
              Text(
                '✦',
                style: TextStyle(fontSize: 13, color: Color(0xFF6BAED4)),
              ),
              SizedBox(width: 7),
              Text(
                'QUOTE OF THE DAY',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A6FA5),
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF6BAED4),
                  ),
                ),
              ),
            )
          else
            Text(
              '\u201c${_quote?.text ?? 'You are growing gently, one day at a time.'}\u201d',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1A3A5C),
                height: 1.45,
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

  static const _cards = [
    _FeatureData(
      label: 'JOURNAL',
      icon: Icons.menu_book_outlined,
      gradientStart: Color(0xFFD6ECFA),
      gradientEnd: Color(0xFFBDD9EF),
      iconBg: Color(0xFFFFFFFF),
      iconColor: Color(0xFF1A3A5C),
    ),
    _FeatureData(
      label: 'TIMER',
      icon: Icons.timer_outlined,
      gradientStart: Color(0xFFD6ECFA),
      gradientEnd: Color(0xFFBDD9EF),
      iconBg: Color(0xFFFFFFFF),
      iconColor: Color(0xFF1A3A5C),
    ),
    _FeatureData(
      label: 'PROGRESS',
      icon: Icons.bar_chart_rounded,
      gradientStart: Color(0xFFD6ECFA),
      gradientEnd: Color(0xFFBDD9EF),
      iconBg: Color(0xFFFFFFFF),
      iconColor: Color(0xFF1A3A5C),
    ),
    _FeatureData(
      label: 'MINDFUL',
      icon: Icons.eco_outlined,
      gradientStart: Color(0xFFD6ECFA),
      gradientEnd: Color(0xFFBDD9EF),
      iconBg: Color(0xFFFFFFFF),
      iconColor: Color(0xFF1A3A5C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: _cards.map((c) => _FeatureCard(data: c)).toList(),
    );
  }
}

Widget _routeFor(String label) {
  switch (label) {
    case 'JOURNAL':
      return const JournalScreen();
    case 'TIMER':
      return const ErpTimerScreen();
    case 'PROGRESS':
      return const ProgressScreen();
    case 'MINDFUL':
      return const MindfulScreen();
    default:
      return const SizedBox();
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => _routeFor(data.label))),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [data.gradientStart, data.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: data.iconBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(data.icon, size: 34, color: data.iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A3A5C),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureData {
  final String label;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final Color iconBg;
  final Color iconColor;

  const _FeatureData({
    required this.label,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.iconBg,
    required this.iconColor,
  });
}
