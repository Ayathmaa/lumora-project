import 'package:flutter/material.dart';
import 'package:lumora_flutter/widgets/lumora_nav_bar.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kBarTrack = Color(0xFFE0EAF4);

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _navIndex = 0;

  static const _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  // 1 = completed, 0.5 = partial, 0 = missed
  static const _weekActivity = [1.0, 1.0, 0.5, 1.0, 0.0, 0.0, 0.0];

  final _stats = [
    _Stat(
      label: 'Streak',
      value: '4 days',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF8C69),
    ),
    _Stat(
      label: 'Sessions',
      value: '12',
      icon: Icons.timer_rounded,
      color: Color(0xFF6BAED4),
    ),
    _Stat(
      label: 'Journal',
      value: '9 entries',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF80C9A4),
    ),
    _Stat(
      label: 'Level',
      value: 'Level 3',
      icon: Icons.star_rounded,
      color: Color(0xFFFFCC55),
    ),
  ];

  final _achievements = [
    _Achievement(
      title: 'First Step',
      desc: 'Completed your first ERP session',
      earned: true,
    ),
    _Achievement(
      title: 'Consistent',
      desc: '3-day check-in streak',
      earned: true,
    ),
    _Achievement(
      title: 'Reflective',
      desc: 'Wrote 5 journal entries',
      earned: true,
    ),
    _Achievement(
      title: 'Brave Heart',
      desc: 'Completed a Level 5 exposure',
      earned: false,
    ),
    _Achievement(
      title: 'Mindful Week',
      desc: '7 Mindful sessions in a row',
      earned: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _kNavy,
                        size: 18,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kNavy,
                        ),
                      ),
                      Text(
                        'Track your healing journey',
                        style: TextStyle(fontSize: 12, color: _kSubtitle),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── XP card ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kNavy,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Level 3 – Blooming Soul',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '320 / 1000 XP',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.32,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '680 XP to next level',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats grid ────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: _stats.map((s) => _StatCard(stat: s)).toList(),
              ),
              const SizedBox(height: 16),

              // ── Weekly activity ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final v = _weekActivity[i];
                        return Column(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    v == 1.0
                                        ? _kBlue
                                        : v == 0.5
                                        ? _kBlue.withValues(alpha: 0.4)
                                        : _kBarTrack,
                              ),
                              child:
                                  v > 0
                                      ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _weekDays[i],
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kSubtitle,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Achievements ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._achievements.map((a) => _AchievementRow(item: a)),
                  ],
                ),
              ),
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

// ── Stat card ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
                  ),
                ),
                Text(
                  stat.label,
                  style: const TextStyle(fontSize: 11, color: _kSubtitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievement row ───────────────────────────────────────────────────────
class _AchievementRow extends StatelessWidget {
  final _Achievement item;
  const _AchievementRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  item.earned
                      ? const Color(0xFFFFCC55).withValues(alpha: 0.2)
                      : _kBarTrack,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.earned
                  ? Icons.emoji_events_rounded
                  : Icons.lock_outline_rounded,
              color: item.earned ? const Color(0xFFFFCC55) : _kSubtitle,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: item.earned ? _kNavy : _kSubtitle,
                  ),
                ),
                Text(
                  item.desc,
                  style: const TextStyle(fontSize: 11, color: _kSubtitle),
                ),
              ],
            ),
          ),
          if (item.earned)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF80C9A4),
              size: 18,
            ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _Achievement {
  final String title;
  final String desc;
  final bool earned;
  const _Achievement({
    required this.title,
    required this.desc,
    required this.earned,
  });
}
