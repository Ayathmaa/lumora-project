import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'breathing/box_breathing_screen.dart';
import 'breathing/panic_reset_screen.dart';
import 'breathing/relaxation_478_screen.dart';
import 'breathing/slow_deep_breathing_screen.dart';

const _kBg = Color(0xFFD0E4F4);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);
const _kChipBg = Color(0xFFDEECF8);
const _kStatBg = Color(0xFFEFF5FB);
const _kHeaderGoalDays = 30;

const _kHabitOptions = [
  'Smoking',
  'Vaping',
  'Alcohol',
  'Nail biting',
  'Social media overuse',
  'Sugar cravings',
  'Late night snacking',
  'Pornography',
];

const _kWeekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class MindfulScreen extends StatefulWidget {
  const MindfulScreen({super.key});

  @override
  State<MindfulScreen> createState() => _MindfulScreenState();
}

class _MindfulScreenState extends State<MindfulScreen> {
  int? _selectedMood;
  final _noteCtrl = TextEditingController();
  bool _isHabitLoading = true;
  bool _isHabitSaving = false;
  bool _didPromptForHabit = false;
  List<_HabitTracker> _habits = const [];
  String? _selectedHabitId;
  final _dropdownKey = GlobalKey();
  OverlayEntry? _dropdownOverlay;

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

  void _openBreathing(String label) {
    final Widget? screen = switch (label) {
      '4-4-4-4 Box Breathing' => const BoxBreathingScreen(),
      '4-7-8 Relaxation' => const Relaxation478Screen(),
      'Slow Deep Breathing' => const SlowDeepBreathingScreen(),
      'Panic Reset Breath' => const PanicResetScreen(),
      _ => null,
    };
    if (screen == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => screen,
      ),
    );
  }

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>? get _habitCollection {
    final uid = _user?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habit_trackers');
  }

  _HabitTracker? get _selectedHabit {
    if (_habits.isEmpty) return null;
    for (final habit in _habits) {
      if (habit.id == _selectedHabitId) return habit;
    }
    return _habits.first;
  }

  _HabitStats get _selectedHabitStats {
    final habit = _selectedHabit;
    if (habit == null) return const _HabitStats.empty();
    return _HabitStats.fromMarkedDates(habit.markedDates);
  }

  @override
  void initState() {
    super.initState();
    _loadHabitTrackers();
  }

  @override
  void dispose() {
    _hideHabitSwitcher();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHabitTrackers({bool promptIfEmpty = true}) async {
    final collection = _habitCollection;
    if (collection == null) {
      if (!mounted) return;
      setState(() {
        _isHabitLoading = false;
        _habits = const [];
        _selectedHabitId = null;
      });
      return;
    }

    try {
      final snapshot = await collection.orderBy('createdAt').get();
      final habits = snapshot.docs
          .map((doc) => _HabitTracker.fromDoc(doc))
          .toList(growable: false);

      if (!mounted) return;

      setState(() {
        _isHabitLoading = false;
        _habits = habits;
        if (habits.isEmpty) {
          _selectedHabitId = null;
        } else if (!habits.any((habit) => habit.id == _selectedHabitId)) {
          _selectedHabitId = habits.first.id;
        }
      });

      if (promptIfEmpty && habits.isEmpty && !_didPromptForHabit) {
        _didPromptForHabit = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showHabitSetupDialog(isInitialPrompt: true);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isHabitLoading = false);
      _showSnackBar('Could not load habit tracker: $e', isError: true);
    }
  }

  Future<void> _showHabitSetupDialog({bool isInitialPrompt = false}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final customController = TextEditingController();
        String? selectedHabit;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              title: Text(
                isInitialPrompt ? 'Choose a habit to avoid' : 'Add a habit',
                style: const TextStyle(
                  color: _kNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pick one from the list or type your own.',
                      style: TextStyle(
                        color: _kSubtitle,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children:
                          _kHabitOptions.map((habit) {
                            final isSelected = selectedHabit == habit;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setModalState(() {
                                  selectedHabit = habit;
                                  customController.clear();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        size: 20,
                                        color: isSelected ? _kBlue : _kSubtitle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        habit,
                                        style: TextStyle(
                                          color:
                                              isSelected ? _kNavy : _kSubtitle,
                                          fontSize: 14,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (selectedHabit != null) {
                          setModalState(() => selectedHabit = null);
                        } else {
                          setModalState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Type a custom habit',
                        hintStyle: const TextStyle(color: _kSubtitle),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: _kSubtitle),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final customName = customController.text.trim();
                    final chosenName =
                        customName.isNotEmpty ? customName : selectedHabit;
                    if (chosenName == null || chosenName.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(chosenName.trim());
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    await _createHabit(result);
  }

  Future<void> _createHabit(String rawName) async {
    final collection = _habitCollection;
    if (collection == null) {
      _showSnackBar('You need to be logged in to track habits.', isError: true);
      return;
    }

    final cleanedName = _cleanHabitName(rawName);
    final normalizedName = _normalizeHabitName(cleanedName);
    if (normalizedName.isEmpty) return;

    final existing = _habits.where(
      (habit) => habit.normalizedName == normalizedName,
    );
    if (existing.isNotEmpty) {
      setState(() => _selectedHabitId = existing.first.id);
      _showSnackBar('${existing.first.name} is already being tracked.');
      return;
    }

    setState(() => _isHabitSaving = true);
    try {
      final docId = _habitDocId(normalizedName);
      await collection.doc(docId).set({
        'name': cleanedName,
        'normalizedName': normalizedName,
        'markedDates': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _selectedHabitId = docId);
      await _loadHabitTrackers(promptIfEmpty: false);
      if (!mounted) return;
      _showSnackBar('$cleanedName added to your tracker.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Could not add habit: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isHabitSaving = false);
      }
    }
  }

  Future<void> _markHabitFreeDay(DateTime date) async {
    final collection = _habitCollection;
    final habit = _selectedHabit;
    if (collection == null || habit == null || _isHabitSaving) return;

    final dateKey = _dateKey(date);
    if (habit.markedDates.contains(dateKey)) return;

    // Optimistic update — mark instantly in local state
    setState(() {
      _habits =
          _habits.map((h) {
            if (h.id != habit.id) return h;
            return _HabitTracker(
              id: h.id,
              name: h.name,
              normalizedName: h.normalizedName,
              markedDates: [...h.markedDates, dateKey]..sort(),
            );
          }).toList();
    });

    try {
      await collection.doc(habit.id).update({
        'markedDates': FieldValue.arrayUnion([dateKey]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Revert on failure
      if (!mounted) return;
      setState(() {
        _habits =
            _habits.map((h) {
              if (h.id != habit.id) return h;
              return _HabitTracker(
                id: h.id,
                name: h.name,
                normalizedName: h.normalizedName,
                markedDates: h.markedDates.where((d) => d != dateKey).toList(),
              );
            }).toList();
      });
      _showSnackBar('Could not save this day: $e', isError: true);
    }
  }

  void _showHabitSwitcher() {
    if (_dropdownOverlay != null) {
      _hideHabitSwitcher();
      return;
    }
    final renderBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _dropdownOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _hideHabitSwitcher,
          child: Stack(
            children: [
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 4,
                width: size.width,
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              _habits.map((habit) {
                                final isSelected = habit.id == _selectedHabitId;
                                return InkWell(
                                  onTap: () {
                                    setState(() => _selectedHabitId = habit.id);
                                    _hideHabitSwitcher();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            habit.name,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? _kNavy
                                                      : _kSubtitle,
                                              fontSize: 14,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_rounded,
                                            color: _kBlue,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context).insert(_dropdownOverlay!);
  }

  void _hideHabitSwitcher() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _kBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedHabit = _selectedHabit;
    final selectedStats = _selectedHabitStats;
    final headerTitle =
        selectedHabit == null
            ? 'Build your freedom streak'
            : '${selectedStats.currentStreak} Day Freedom Streak';
    final headerProgress =
        selectedStats.currentStreak <= 0
            ? 0.0
            : (selectedStats.currentStreak.clamp(0, _kHeaderGoalDays) /
                    _kHeaderGoalDays)
                .toDouble();
    final headerSubtitle =
        selectedHabit == null
            ? 'Small practices. Big change.'
            : 'Tracking freedom from ${selectedHabit.name.toLowerCase()}.';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(
                title: headerTitle,
                subtitle: headerSubtitle,
                progress: headerProgress,
              ),
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

  Widget _buildHeader({
    required String title,
    required String subtitle,
    required double progress,
  }) {
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
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Text(
                '30 day goal',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

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
                    onTap: () => _openBreathing(label),
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

  Widget _buildHabitTracker() {
    final now = DateTime.now();
    final selectedHabit = _selectedHabit;
    final stats = _selectedHabitStats;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 28, 20),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Habit Freedom Tracker',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isHabitSaving ? null : _showHabitSetupDialog,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a habit, mark every habit-free day, and let the streak grow.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_isHabitLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_user == null)
            _buildHabitInfoCard(
              child: const _HabitEmptyState(
                title: 'Sign in to start tracking',
                subtitle:
                    'Your tracker is saved per user, so this feature needs an account.',
              ),
            )
          else if (_habits.isEmpty)
            _buildHabitInfoCard(
              child: Column(
                children: [
                  const _HabitEmptyState(
                    title: 'Choose your first habit',
                    subtitle:
                        'Pick from the list or add your own custom habit.',
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _isHabitSaving
                            ? null
                            : () =>
                                _showHabitSetupDialog(isInitialPrompt: true),
                    child: const Text('Set up habit tracker'),
                  ),
                ],
              ),
            )
          else ...[
            GestureDetector(
              onTap: _isHabitSaving ? null : _showHabitSwitcher,
              child: Container(
                key: _dropdownKey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedHabit?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildHabitInfoCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          selectedHabit!.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stats.currentStreak >= 4 ? '🔥' : '💙',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats.currentStreak >= 4
                        ? 'You are on a real streak. Keep protecting it.'
                        : 'Streak badge unlocks after 4 consecutive habit-free days.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrackerStat(
                        label: 'Longest',
                        value: '${stats.longestStreak}',
                      ),
                      const SizedBox(width: 28),
                      _TrackerStat(
                        label: 'Current',
                        value: '${stats.currentStreak}',
                      ),
                      const SizedBox(width: 28),
                      _TrackerStat(
                        label: 'Days Free',
                        value: '${stats.totalMarkedDays}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _monthLabel(now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Once marked, a day stays locked.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children:
                  _kWeekdayLabels
                      .map(
                        (label) => Expanded(
                          child: Center(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 8),
            _buildHabitCalendar(now, selectedHabit),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _buildHabitCalendar(DateTime now, _HabitTracker selectedHabit) {
    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final leadingEmptyCells = monthStart.weekday - 1;
    final totalItems = leadingEmptyCells + daysInMonth;
    final today = DateTime(now.year, now.month, now.day);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < leadingEmptyCells) {
          return const SizedBox.shrink();
        }

        final day = index - leadingEmptyCells + 1;
        final date = DateTime(now.year, now.month, day);
        final dateKey = _dateKey(date);
        final isChecked = selectedHabit.markedDates.contains(dateKey);
        final isFuture = date.isAfter(today);
        final isToday = day == now.day;

        return GestureDetector(
          onTap:
              isFuture || isChecked || _isHabitSaving
                  ? null
                  : () => _markHabitFreeDay(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color:
                  isChecked
                      ? Colors.white
                      : Colors.white.withValues(alpha: isFuture ? 0.08 : 0.2),
              borderRadius: BorderRadius.circular(8),
              border:
                  isToday && !isChecked
                      ? Border.all(color: Colors.white70, width: 1)
                      : null,
            ),
            child:
                isChecked
                    ? const Icon(Icons.check_rounded, color: _kBlue, size: 16)
                    : Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              isFuture
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.white,
                        ),
                      ),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildMindfulGrowth() {
    final selectedStats = _selectedHabitStats;
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
            children: [
              _GrowthStat(
                icon: Icons.list_alt_rounded,
                value: '${_habits.length}',
                label: 'Tracked Habits',
              ),
              _GrowthStat(
                icon: Icons.calendar_today_outlined,
                value: '${selectedStats.totalMarkedDays}',
                label: 'Habit-Free Days',
              ),
              _GrowthStat(
                icon: Icons.local_fire_department_rounded,
                value: '${selectedStats.currentStreak}',
                label: 'Current Streak',
              ),
              _GrowthStat(
                icon: Icons.emoji_events_outlined,
                value: '${selectedStats.longestStreak}',
                label: 'Longest Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  String _habitDocId(String normalizedName) {
    final sanitized = normalizedName
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return sanitized.isEmpty ? 'habit' : sanitized;
  }

  String _cleanHabitName(String name) {
    final collapsed = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return collapsed;
    return collapsed[0].toUpperCase() + collapsed.substring(1);
  }

  String _normalizeHabitName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

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

class _HabitEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HabitEmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.track_changes_rounded, color: Colors.white, size: 28),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _HabitTracker {
  final String id;
  final String name;
  final String normalizedName;
  final List<String> markedDates;

  const _HabitTracker({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.markedDates,
  });

  factory _HabitTracker.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawMarkedDates = data['markedDates'] as List<dynamic>? ?? const [];
    return _HabitTracker(
      id: doc.id,
      name: (data['name'] as String? ?? 'Habit').trim(),
      normalizedName:
          (data['normalizedName'] as String? ?? doc.id).trim().toLowerCase(),
      markedDates: rawMarkedDates.whereType<String>().toSet().toList()..sort(),
    );
  }
}

class _HabitStats {
  final int currentStreak;
  final int longestStreak;
  final int totalMarkedDays;

  const _HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalMarkedDays,
  });

  const _HabitStats.empty()
    : currentStreak = 0,
      longestStreak = 0,
      totalMarkedDays = 0;

  factory _HabitStats.fromMarkedDates(List<String> markedDateKeys) {
    if (markedDateKeys.isEmpty) {
      return const _HabitStats.empty();
    }

    final uniqueDates =
        markedDateKeys
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .map((date) => DateTime(date.year, date.month, date.day))
            .toSet()
            .toList()
          ..sort();

    if (uniqueDates.isEmpty) {
      return const _HabitStats.empty();
    }

    var longest = 1;
    var run = 1;

    for (var i = 1; i < uniqueDates.length; i++) {
      final previous = uniqueDates[i - 1];
      final current = uniqueDates[i];
      final difference = current.difference(previous).inDays;
      if (difference == 1) {
        run += 1;
      } else if (difference > 1) {
        run = 1;
      }
      if (run > longest) {
        longest = run;
      }
    }

    var currentStreak = 1;
    for (var i = uniqueDates.length - 1; i > 0; i--) {
      final current = uniqueDates[i];
      final previous = uniqueDates[i - 1];
      if (current.difference(previous).inDays == 1) {
        currentStreak += 1;
      } else {
        break;
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final latestMarked = uniqueDates.last;
    final daysSinceLatest = today.difference(latestMarked).inDays;
    if (daysSinceLatest > 1) {
      currentStreak = 0;
    }

    return _HabitStats(
      currentStreak: currentStreak,
      longestStreak: longest,
      totalMarkedDays: uniqueDates.length,
    );
  }
}

class _Meditation {
  final String title;
  final String duration;
  final IconData icon;
  final Color color;
  const _Meditation(this.title, this.duration, this.icon, this.color);
}
