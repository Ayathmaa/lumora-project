import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lumora_flutter/services/gamification_service.dart';
import 'package:lumora_flutter/services/gamification_utils.dart';
import 'package:lumora_flutter/services/progress_service.dart';
import 'package:lumora_flutter/services/streak_calculator.dart';

const _kBg = Color(0xFFD0E4F4);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kIconBg = Color(0xFFD6ECFA);

const _kDotJournal = Colors.blue;
const _kDotErp = Colors.orange;
const _kDotBreathing = Colors.green;
const _kDotHabit = Colors.purple;

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ActivityEvent> _allEvents = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final events = await ProgressService().fetchAllActivities();
    if (mounted) {
      setState(() {
        _allEvents = events;
        _isLoadingEvents = false;
      });
    }
  }

  void _showLevelJourneyModal(BuildContext context, int currentXp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _LevelJourneyModal(currentXp: currentXp);
      },
    );
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
              // ── 1. Level and XP Header ───────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 24),

              // ── 2. Individual Streaks ──────────────────────────────────────
              const Text(
                'Active Streaks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 12),
              _isLoadingEvents
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStreaksGrid(),

              const SizedBox(height: 24),

              // ── 3. Mood Overview Stub ──────────────────────────────────────
              const Text(
                'Mood Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Mood analytics coming soon...',
                  style: TextStyle(
                    color: _kSubtitle,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 4. Journey Calendar ────────────────────────────────────────
              const Text(
                'Journey Calendar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 8),
                  ],
                ),
                padding: const EdgeInsets.only(bottom: 12),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox();
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              events
                                  .map(
                                    (e) => _buildEventMarker(
                                      (e as ActivityEvent).type,
                                    ),
                                  )
                                  .toList(),
                        ),
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                    ),
                  ),
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: _kNavy,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: _kBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSelectedDayEvents(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreaksGrid() {
    final journalStreak = StreakCalculator.computeStreak(
      _allEvents.where((e) => e.type == 'Journal').toList(),
    );
    final erpStreak = StreakCalculator.computeStreak(
      _allEvents.where((e) => e.type == 'ERP').toList(),
    );
    final breathingStreak = StreakCalculator.computeStreak(
      _allEvents.where((e) => e.type == 'Breathing').toList(),
    );
    final habitStreak = StreakCalculator.computeStreak(
      _allEvents.where((e) => e.type == 'Habit').toList(),
    );

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [
        _StreakCard('Journal', journalStreak, Icons.menu_book, _kDotJournal),
        _StreakCard('ERP Timer', erpStreak, Icons.timer, _kDotErp),
        _StreakCard('Breathing', breathingStreak, Icons.air, _kDotBreathing),
        _StreakCard(
          'Habits Free',
          habitStreak,
          Icons.calendar_today,
          _kDotHabit,
        ),
      ],
    );
  }

  Widget _buildEventMarker(String type) {
    Color dotColor = Colors.grey;
    if (type == 'Journal') dotColor = _kDotJournal;
    if (type == 'ERP') dotColor = _kDotErp;
    if (type == 'Breathing') dotColor = _kDotBreathing;
    if (type == 'Habit') dotColor = _kDotHabit;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
    );
  }

  List<ActivityEvent> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) => isSameDay(e.date, day)).toList();
  }

  Widget _buildSelectedDayEvents() {
    if (_selectedDay == null) return const SizedBox();
    final dayEvents = _getEventsForDay(_selectedDay!);

    if (dayEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No activities on this day.',
            style: TextStyle(color: _kSubtitle),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          dayEvents.map((e) {
            Color iconColor = Colors.grey;
            IconData icon = Icons.check_circle;
            if (e.type == 'Journal') {
              iconColor = _kDotJournal;
              icon = Icons.menu_book;
            }
            if (e.type == 'ERP') {
              iconColor = _kDotErp;
              icon = Icons.timer;
            }
            if (e.type == 'Breathing') {
              iconColor = _kDotBreathing;
              icon = Icons.air;
            }
            if (e.type == 'Habit') {
              iconColor = _kDotHabit;
              icon = Icons.calendar_today;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _kNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.detail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kSubtitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<GamificationStats>(
      stream: GamificationService().getStatsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const GamificationStats();
        final levelDisplay = GamificationUtils.getLevelDisplay(stats.xp);
        final progress = GamificationUtils.getProgress(stats.xp);
        final nextLimit = GamificationUtils.getNextXpLimit(stats.xp);

        return GestureDetector(
          onTap: () => _showLevelJourneyModal(context, stats.xp),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: _kBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Journey',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  levelDisplay,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${stats.xp} / $nextLimit XP (Tap here)',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String title;
  final int streakLength;
  final IconData icon;
  final Color color;

  const _StreakCard(this.title, this.streakLength, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kSubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$streakLength Days',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
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

class _LevelJourneyModal extends StatelessWidget {
  final int currentXp;

  const _LevelJourneyModal({required this.currentXp});

  @override
  Widget build(BuildContext context) {
    final levels = GamificationUtils.getAllLevels();
    final currentLevelBase = GamificationUtils.getCurrentLevelBase(currentXp);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Level Journey',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final xpRequirement = levels[index].keys.first;
                final title = levels[index].values.first;
                final isAchieved = currentXp >= xpRequirement;
                final isCurrent = xpRequirement == currentLevelBase;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent ? _kIconBg : _kCardBg,
                    border:
                        isCurrent
                            ? Border.all(color: _kBlue, width: 2)
                            : Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAchieved ? Icons.check_circle : Icons.lock_outline,
                        color:
                            isAchieved
                                ? (isCurrent ? _kBlue : Colors.green)
                                : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${index + 1} – $title',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color:
                                    isAchieved ? _kNavy : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '$xpRequirement XP Required',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _kSubtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
