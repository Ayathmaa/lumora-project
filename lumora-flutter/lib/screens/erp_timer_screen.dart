import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _kBg = Color(0xFFD0E4F4);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kIconBg = Color(0xFFD6ECFA);
const _kBlue = Color(0xFF6BAED4);

class _Exercise {
  final IconData icon;
  final String label;
  const _Exercise(this.icon, this.label);
}

class ErpTimerScreen extends StatefulWidget {
  const ErpTimerScreen({super.key});

  @override
  State<ErpTimerScreen> createState() => _ErpTimerScreenState();
}

class _ErpTimerScreenState extends State<ErpTimerScreen> {
  // Timer state
  static const _presets = [5, 10, 15, 20];
  int _selectedMinutes = 10;
  int _secondsRemaining = 10 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _sessionCompleted = false;
  bool _sessionSaved = false;
  Timer? _timer;

  // Anxiety levels
  double _preAnxiety = 5;
  double _postAnxiety = 5;

  // Mindful exercise selection
  String? _selectedExercise;

  // Session reflection
  final TextEditingController _reflectionCtrl = TextEditingController();
  bool _resistedCompulsions = false;

  // Difficulty & triggers
  String? _selectedDifficulty;
  final Set<String> _selectedTriggers = {};

  // Streak
  static const _streak = 7;
  static const _streakGoal = 30;

  static const _exercises = [
    _Exercise(Icons.air, 'Breathing Exercise'),
    _Exercise(Icons.headphones_outlined, 'Guided Meditation'),
    _Exercise(Icons.eco_outlined, 'Grounding'),
    _Exercise(Icons.show_chart_rounded, 'Body Scan'),
  ];

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _triggers = [
    'Contamination',
    'Checking',
    'Social',
    'Intrusive',
    'Symmetry',
    'Harm',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _reflectionCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _secondsRemaining = minutes * 60;
    });
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isPaused = false;
          _sessionCompleted = true;
        });
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resume() {
    _timer?.cancel();
    setState(() => _isPaused = false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isPaused = false;
          _sessionCompleted = true;
        });
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _sessionCompleted = false;
      _sessionSaved = false;
      _secondsRemaining = _selectedMinutes * 60;
    });
  }

  Future<void> _saveSession() async {
    if (_sessionSaved) return; // prevent double-submit

    // If the timer hasn't finished, ask for confirmation
    if (!_sessionCompleted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Session not finished',
                style: TextStyle(
                  color: _kNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              content: const Text(
                "You haven't finished the session timer. If you proceed now the session will be saved as incomplete. Would you like to proceed?",
                style: TextStyle(color: _kSubtitle, fontSize: 13, height: 1.5),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kNavy,
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('No'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Yes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      );
      if (proceed != true) return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data = <String, dynamic>{
      'session_complete': _sessionCompleted ? 1 : 0,
      'duration_mins': _selectedMinutes,
      'pre_anxiety': _preAnxiety.round(),
      'post_anxiety': _postAnxiety.round(),
      'difficulty': _selectedDifficulty,
      'trigger_types': _selectedTriggers.toList(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    final reflection = _reflectionCtrl.text.trim();
    if (reflection.isNotEmpty) {
      data['reflection'] = reflection;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('erp_sessions')
          .add(data);

      if (!mounted) return;
      setState(() => _sessionSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session saved!'),
          backgroundColor: _kBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save session: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String get _timeDisplay {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress =>
      _selectedMinutes == 0
          ? 0
          : 1 - (_secondsRemaining / (_selectedMinutes * 60));

  String get _timerStatus {
    if (_secondsRemaining == 0 && !_isRunning) return 'Done';
    if (_isPaused) return 'Paused';
    if (_isRunning) return 'Running';
    return 'Ready';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSessionHeader(),
              const SizedBox(height: 14),
              _buildAnxietyCard(
                'Pre Anxiety Level',
                _preAnxiety,
                (v) => setState(() => _preAnxiety = v),
              ),
              const SizedBox(height: 14),
              _buildTimerCard(),
              const SizedBox(height: 14),
              _buildAnxietyCard(
                'Post Anxiety Level',
                _postAnxiety,
                (v) => setState(() => _postAnxiety = v),
              ),
              // const SizedBox(height: 14),
              // _buildMindfulExerciseCard(),
              const SizedBox(height: 14),
              _buildReflectionCard(),
              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Session header ───────────────────────────────────────────────────────
  Widget _buildSessionHeader() {
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
              const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ERP Practice Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _ErpSessionHistoryScreen(),
                      ),
                    ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Stay with the feeling. Let it pass naturally.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Day $_streak Streak',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Text(
                '$_streakGoal day goal',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _streak / _streakGoal,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Anxiety level card ────────────────────────────────────────────────────
  Widget _buildAnxietyCard(
    String title,
    double value,
    ValueChanged<double> onChanged,
  ) {
    const labels = ['Calm', 'Mild', 'Moderate', 'High'];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${value.round()}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                    ),
                  ),
                  const TextSpan(
                    text: ' /10',
                    style: TextStyle(fontSize: 16, color: _kSubtitle),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: _kBlue,
              inactiveTrackColor: _kIconBg,
              thumbColor: _kBlue,
              overlayColor: const Color(0x266BAED4),
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  labels
                      .map(
                        (l) => Text(
                          l,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _kSubtitle,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timer card ────────────────────────────────────────────────────────────
  Widget _buildTimerCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
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
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ..._presets.map((m) {
                final active = m == _selectedMinutes;
                return GestureDetector(
                  onTap: () => _selectPreset(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active ? _kBlue : _kIconBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$m min',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : _kBlue,
                      ),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kIconBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 152,
            height: 152,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _isRunning ? _progress : 1,
                    strokeWidth: _isRunning ? 3 : 1.5,
                    backgroundColor: _isRunning ? _kIconBg : Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isRunning ? _kBlue : const Color(0xFFCCCCCC),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timeDisplay,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: _kNavy,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timerStatus,
                      style: const TextStyle(fontSize: 12, color: _kSubtitle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleBtn(
                icon: Icons.refresh_rounded,
                onTap: _reset,
                bg: _kIconBg,
                fg: _kBlue,
              ),
              const SizedBox(width: 20),
              _CircleBtn(
                icon:
                    _isRunning && !_isPaused
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                onTap:
                    _isRunning && !_isPaused
                        ? _pause
                        : (_isPaused ? _resume : _start),
                bg: _kBlue,
                fg: Colors.white,
                size: 64,
                iconSize: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mindful exercise card ─────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildMindfulExerciseCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
            'Add a Mindful Exercise',
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
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
            children:
                _exercises.map((e) {
                  final selected = _selectedExercise == e.label;
                  return GestureDetector(
                    onTap:
                        () => setState(() {
                          _selectedExercise = selected ? null : e.label;
                        }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0x266BAED4) : _kIconBg,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            selected
                                ? Border.all(color: _kBlue, width: 1.5)
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(e.icon, color: _kBlue, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            e.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kNavy,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Reflection card ───────────────────────────────────────────────────────
  Widget _buildReflectionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
            'Session Reflection',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'What did you notice during this session?',
            style: TextStyle(fontSize: 12, color: _kSubtitle),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reflectionCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 13, color: _kNavy),
            decoration: InputDecoration(
              hintText: 'Describe what came up for you...',
              hintStyle: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFEBF4FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap:
                () => setState(
                  () => _resistedCompulsions = !_resistedCompulsions,
                ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _resistedCompulsions ? _kBlue : Colors.transparent,
                    border: Border.all(
                      color:
                          _resistedCompulsions
                              ? _kBlue
                              : const Color(0xFFCCCCCC),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      _resistedCompulsions
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          )
                          : null,
                ),
                const SizedBox(width: 10),
                const Text(
                  'I resisted compulsions',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_resistedCompulsions) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check, color: _kBlue, size: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 12,
              color: _kSubtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _difficulties.map((d) {
                  final selected = _selectedDifficulty == d;
                  return GestureDetector(
                    onTap:
                        () => setState(
                          () => _selectedDifficulty = selected ? null : d,
                        ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _kBlue : _kIconBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : _kNavy,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Trigger Type',
            style: TextStyle(
              fontSize: 12,
              color: _kSubtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _triggers.map((t) {
                  final selected = _selectedTriggers.contains(t);
                  return GestureDetector(
                    onTap:
                        () => setState(() {
                          if (selected) {
                            _selectedTriggers.remove(t);
                          } else {
                            _selectedTriggers.add(t);
                          }
                        }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _kBlue : _kIconBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : _kNavy,
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

  // ── Save button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _sessionSaved ? null : _saveSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: _sessionSaved ? Colors.grey.shade300 : _kBlue,
          foregroundColor: _sessionSaved ? Colors.grey.shade500 : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _sessionSaved ? 'Session Saved' : 'Save Session',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  final double size;
  final double iconSize;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.fg,
    this.size = 52,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: iconSize),
      ),
    );
  }
}

// ── Session History Screen ────────────────────────────────────────────────
class _ErpSessionHistoryScreen extends StatelessWidget {
  const _ErpSessionHistoryScreen();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _kNavy,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Session History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                    ),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child:
                  uid == null
                      ? const Center(child: Text('Not signed in'))
                      : StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('erp_sessions')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: _kBlue),
                            );
                          }
                          final docs = snap.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No sessions yet.',
                                style: TextStyle(color: _kSubtitle),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: docs.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final d = docs[i].data() as Map<String, dynamic>;
                              final ts = d['timestamp'] as Timestamp?;
                              final date =
                                  ts != null ? _formatDate(ts.toDate()) : '—';
                              final complete =
                                  (d['session_complete'] as int? ?? 0) == 1;
                              final triggers =
                                  (d['trigger_types'] as List?)
                                      ?.cast<String>() ??
                                  [];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _kCardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _kNavy,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                complete
                                                    ? const Color(0xFFD6F0E0)
                                                    : const Color(0xFFFFE4E4),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            complete
                                                ? 'Completed'
                                                : 'Incomplete',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  complete
                                                      ? const Color(0xFF2E7D52)
                                                      : const Color(0xFFB02020),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _HistoryStat(
                                          label: 'Duration',
                                          value:
                                              '${d['duration_mins'] ?? '—'} min',
                                        ),
                                        const SizedBox(width: 16),
                                        _HistoryStat(
                                          label: 'Pre',
                                          value:
                                              '${d['pre_anxiety'] ?? '—'}/10',
                                        ),
                                        const SizedBox(width: 16),
                                        _HistoryStat(
                                          label: 'Post',
                                          value:
                                              '${d['post_anxiety'] ?? '—'}/10',
                                        ),
                                        if (d['difficulty'] != null) ...[
                                          const SizedBox(width: 16),
                                          _HistoryStat(
                                            label: 'Difficulty',
                                            value: d['difficulty'] as String,
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (triggers.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children:
                                            triggers
                                                .map(
                                                  (t) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _kIconBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      t,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: _kBlue,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ],
                                    if ((d['reflection'] as String?)
                                            ?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        d['reflection'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _kSubtitle,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m';
  }
}

class _HistoryStat extends StatelessWidget {
  final String label;
  final String value;
  const _HistoryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _kSubtitle)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kNavy,
          ),
        ),
      ],
    );
  }
}
