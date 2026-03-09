import 'package:flutter/material.dart';

// ── colour palette ──────────────────────────────────────────────────────────
const _kBg = Color(0xFFD0E4F4);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kChipBg = Color(0xFFDEECF8);
const _kStatBg = Color(0xFFEFF5FB);
// ────────────────────────────────────────────────────────────────────────────

class MindfulScreen extends StatefulWidget {
  const MindfulScreen({super.key});

  @override
  State<MindfulScreen> createState() => _MindfulScreenState();
}

class _MindfulScreenState extends State<MindfulScreen> {
  int? _selectedMood;
  final _noteCtrl = TextEditingController();
  final Set<int> _habitDays = {1, 2, 3, 5, 8, 10, 12, 15, 18, 21, 22, 24};

  static const _meditations = [
    _Meditation(
      '5 Min Calm Reset',
      '5:00',
      Icons.favorite_rounded,
      Color(0xFF6BAED4),
    ),
    _Meditation(
      '10 Min Anxiety Relief',
      '10:00',
      Icons.psychology_rounded,
      Color(0xFF80C9A4),
    ),
    _Meditation(
      'Sleep Meditation',
      '15:00',
      Icons.nightlight_round,
      Color(0xFF9B8FD4),
    ),
    _Meditation(
      'Self-Compassion Practice',
      '8:00',
      Icons.auto_awesome_rounded,
      Color(0xFFFFCC55),
    ),
  ];

  static const _breathingExercises = [
    '4-4-4-4 Box Breathing',
    '4-7-8 Relaxation',
    'Slow Deep Breathing',
    'Panic Reset Breath',
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildMeditations(),
              const SizedBox(height: 16),
              _buildBreathingExercises(),
              const SizedBox(height: 16),
              _buildHabitTracker(),
              const SizedBox(height: 16),
              _buildMindfulGrowth(),
              const SizedBox(height: 16),
              _buildPostSessionMood(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header card ───────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('🌿', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Mindful Space',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Small practices. Big change.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '7 Day Mindful Streak',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '30 day goal',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 7 / 30,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Meditations ───────────────────────────────────────────────────────────
  Widget _buildMeditations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            'Meditations',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _meditations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _MeditationCard(meditation: _meditations[i]),
          ),
        ),
      ],
    );
  }

  // ── Breathing exercises ───────────────────────────────────────────────────
  Widget _buildBreathingExercises() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Breathing Exercises',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
            children:
                _breathingExercises.map((label) {
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _kChipBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kNavy,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Habit Freedom Tracker ─────────────────────────────────────────────────
  Widget _buildHabitTracker() {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final today = now.day;
    const longest = 15;
    final current = _habitDays.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Habit Freedom Tracker',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mark your strength each day.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$current',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Days Strong',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('💙', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TrackerStat(label: 'Longest', value: '$longest'),
                    const SizedBox(width: 32),
                    _TrackerStat(label: 'Current', value: '$current'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth,
            itemBuilder: (_, i) {
              final day = i + 1;
              final isChecked = _habitDays.contains(day);
              final isFuture = day > today;
              return GestureDetector(
                onTap:
                    isFuture
                        ? null
                        : () {
                          setState(() {
                            if (isChecked) {
                              _habitDays.remove(day);
                            } else {
                              _habitDays.add(day);
                            }
                          });
                        },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isChecked
                            ? Colors.white
                            : Colors.white.withValues(
                              alpha: isFuture ? 0.1 : 0.2,
                            ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      isChecked
                          ? const Icon(
                            Icons.check_rounded,
                            color: _kBlue,
                            size: 16,
                          )
                          : Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    isFuture
                                        ? Colors.white.withValues(alpha: 0.35)
                                        : Colors.white,
                              ),
                            ),
                          ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Mindful Growth ────────────────────────────────────────────────────────
  Widget _buildMindfulGrowth() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Mindful Growth',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: const [
              _GrowthStat(
                icon: Icons.timer_outlined,
                value: '142',
                label: 'Meditation Minutes',
              ),
              _GrowthStat(
                icon: Icons.air_rounded,
                value: '28',
                label: 'Breathing Sessions',
              ),
              _GrowthStat(
                icon: Icons.calendar_today_outlined,
                value: '12',
                label: 'Habit-Free Days',
              ),
              _GrowthStat(
                icon: Icons.trending_up_rounded,
                value: '85%',
                label: 'Weekly Consistency',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Post-session mood ─────────────────────────────────────────────────────
  Widget _buildPostSessionMood() {
    const emojis = ['😢', '😔', '😐', '🙂', '😊'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'After your session, how do you feel?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 2),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(emojis.length, (i) {
              final selected = _selectedMood == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = i),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? _kBlue.withValues(alpha: 0.15) : _kStatBg,
                    shape: BoxShape.circle,
                    border:
                        selected ? Border.all(color: _kBlue, width: 2) : null,
                  ),
                  child: Center(
                    child: Text(
                      emojis[i],
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note...',
              hintStyle: const TextStyle(
                color: Color(0xFFABC4D8),
                fontSize: 14,
              ),
              filled: true,
              fillColor: _kStatBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Meditation card
// ════════════════════════════════════════════════════════════════════════════
class _MeditationCard extends StatelessWidget {
  final _Meditation meditation;
  const _MeditationCard({required this.meditation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: meditation.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(meditation.icon, color: meditation.color, size: 22),
          ),
          const SizedBox(height: 7),
          Text(
            meditation.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _kNavy,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meditation.duration,
            style: const TextStyle(fontSize: 11, color: _kSubtitle),
          ),
          const SizedBox(height: 7),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFDEECF8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: _kBlue,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Tracker stat (inside blue card)
// ════════════════════════════════════════════════════════════════════════════
class _TrackerStat extends StatelessWidget {
  final String label;
  final String value;
  const _TrackerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Growth stat tile
// ════════════════════════════════════════════════════════════════════════════
class _GrowthStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _GrowthStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: _kStatBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _kBlue, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: _kSubtitle,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Data model
// ════════════════════════════════════════════════════════════════════════════
class _Meditation {
  final String title;
  final String duration;
  final IconData icon;
  final Color color;
  const _Meditation(this.title, this.duration, this.icon, this.color);
}

// placeholder so the rest of the old file below gets replaced too
