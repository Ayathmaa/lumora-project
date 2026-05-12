import 'dart:async';
import 'package:flutter/material.dart';

import '../models/meditation.dart';
import '../services/erp_timer_service.dart';
import '../services/meditation_catalog_service.dart';
import 'erp_video_player_screen.dart';

const _kBg = Color(0xFFD0E4F4);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kIconBg = Color(0xFFD6ECFA);
const _kBlue = Color(0xFF6BAED4);
const _kStatBg = Color(0xFFEFF5FB);

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
  Meditation? _selectedMeditation;

  // Anxiety levels
  double _preAnxiety = 5;
  double _postAnxiety = 5;

  // Session reflection
  final TextEditingController _reflectionCtrl = TextEditingController();
  bool _resistedCompulsions = false;

  // Difficulty & triggers
  String? _selectedDifficulty;
  final Set<String> _selectedTriggers = {};

  final _erpService = ErpTimerService();
  final _meditationCatalogService = MeditationCatalogService();

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
      _selectedMeditation = null;
      _sessionCompleted = false;
      _sessionSaved = false;
    });
  }

  Future<void> _start() async {
    final meditation = _selectedMeditation;
    if (meditation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select a $_selectedMinutes min video first.'),
          backgroundColor: _kBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _sessionCompleted = false;
      _sessionSaved = false;
      _secondsRemaining = _selectedMinutes * 60;
    });

    final completed = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder:
            (_, __, ___) => ErpVideoPlayerScreen(
              meditation: meditation,
              timerDuration: Duration(minutes: _selectedMinutes),
            ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _sessionCompleted = completed == true;
      _secondsRemaining = completed == true ? 0 : _selectedMinutes * 60;
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

    if (!_sessionCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complete the full ERP timer before saving.'),
          backgroundColor: _kBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      await _erpService.saveSession(
        sessionCompleted: _sessionCompleted,
        durationMins: _selectedMinutes,
        preAnxiety: _preAnxiety.round(),
        postAnxiety: _postAnxiety.round(),
        difficulty: _selectedDifficulty,
        triggerTypes: _selectedTriggers.toList(),
        reflection:
            _reflectionCtrl.text.trim().isEmpty
                ? null
                : _reflectionCtrl.text.trim(),
      );

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
              const SizedBox(height: 14),
              _buildMeditationSuggestionsCard(),
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
                bg: _selectedMeditation == null ? Colors.grey.shade300 : _kBlue,
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

  // ── Meditation suggestions ───────────────────────────────────────────────
  Widget _buildMeditationSuggestionsCard() {
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Meditation Suggestions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_selectedMinutes min',
                  style: const TextStyle(
                    color: _kBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a video that matches your ERP timer before starting.',
            style: TextStyle(fontSize: 12, color: _kSubtitle, height: 1.4),
          ),
          const SizedBox(height: 14),
          if (!_meditationCatalogService.isSignedIn)
            const _MeditationSuggestionStatus(
              title: 'Sign in to access meditation videos',
              icon: Icons.lock_outline_rounded,
            )
          else
            StreamBuilder<List<Meditation>>(
              stream: _meditationCatalogService.streamMeditations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 188,
                    child: Center(
                      child: CircularProgressIndicator(color: _kBlue),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const _MeditationSuggestionStatus(
                    title: 'Could not load meditation videos',
                    icon: Icons.error_outline_rounded,
                  );
                }

                final meditations = snapshot.data ?? const <Meditation>[];
                final suggestions = meditations
                    .where(
                      (meditation) =>
                          meditation.durationMinutes == _selectedMinutes ||
                          meditation.category.durationMinutes ==
                              _selectedMinutes,
                    )
                    .toList(growable: false);

                if (suggestions.isEmpty) {
                  return _MeditationSuggestionStatus(
                    title: 'No $_selectedMinutes min meditations yet',
                    icon: Icons.play_disabled_outlined,
                  );
                }

                return SizedBox(
                  height: 188,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final meditation = suggestions[i];
                      final selected = _selectedMeditation?.id == meditation.id;
                      return _ErpMeditationCard(
                        meditation: meditation,
                        selected: selected,
                        onTap: () {
                          if (_isRunning) return;
                          setState(() => _selectedMeditation = meditation);
                        },
                      );
                    },
                  ),
                );
              },
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
    final canSave = _sessionCompleted && !_sessionSaved;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canSave ? _saveSession : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSave ? _kBlue : Colors.grey.shade300,
          foregroundColor: canSave ? Colors.white : Colors.grey.shade500,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _sessionSaved
              ? 'Session Saved'
              : (_sessionCompleted ? 'Save Session' : 'Complete Timer to Save'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────
class _ErpMeditationCard extends StatelessWidget {
  final Meditation meditation;
  final bool selected;
  final VoidCallback onTap;

  const _ErpMeditationCard({
    required this.meditation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 156,
        decoration: BoxDecoration(
          color: _kStatBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _kBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    meditation.thumbnailUrl.isEmpty
                        ? Container(
                          color: _kIconBg,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.ondemand_video_rounded,
                            color: _kBlue,
                            size: 30,
                          ),
                        )
                        : Image.network(
                          meditation.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: _kIconBg,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.ondemand_video_rounded,
                                  color: _kBlue,
                                  size: 30,
                                ),
                              ),
                        ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meditation.durationLabel,
                      style: const TextStyle(fontSize: 11.5, color: _kSubtitle),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: _kIconBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: _kBlue,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            selected ? 'Selected' : 'Select',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _kSubtitle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeditationSuggestionStatus extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MeditationSuggestionStatus({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: _kStatBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _kSubtitle,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
class _ErpSessionHistoryScreen extends StatefulWidget {
  const _ErpSessionHistoryScreen();

  @override
  State<_ErpSessionHistoryScreen> createState() =>
      _ErpSessionHistoryScreenState();
}

class _ErpSessionHistoryScreenState extends State<_ErpSessionHistoryScreen> {
  final _scrollController = ScrollController();
  final List<ErpSession> _sessions = [];

  ErpPaginator? _paginator;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _paginator = ErpTimerService().getPaginator();
    _loadMore();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_paginator == null || !_paginator!.hasMore || _paginator!.isFetching) {
      return;
    }

    try {
      final newSessions = await _paginator!.fetchNext();
      if (mounted) {
        setState(() {
          _sessions.addAll(newSessions);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _paginator == null
                      ? const Center(child: Text('Not signed in'))
                      : _hasError
                      ? const Center(
                        child: Text(
                          'Error loading history',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                      : _sessions.isEmpty && !_isLoading
                      ? const Center(
                        child: Text(
                          'No sessions yet.',
                          style: TextStyle(color: _kSubtitle),
                        ),
                      )
                      : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount:
                            _sessions.length + (_paginator!.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == _sessions.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(color: _kBlue),
                              ),
                            );
                          }
                          final s = _sessions[i];
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
                                      s.date,
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
                                            s.complete
                                                ? const Color(0xFFD6F0E0)
                                                : const Color(0xFFFFE4E4),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        s.complete ? 'Completed' : 'Incomplete',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              s.complete
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
                                      value: '${s.durationMins} min',
                                    ),
                                    const SizedBox(width: 16),
                                    _HistoryStat(
                                      label: 'Pre',
                                      value: '${s.preAnxiety}/10',
                                    ),
                                    const SizedBox(width: 16),
                                    _HistoryStat(
                                      label: 'Post',
                                      value: '${s.postAnxiety}/10',
                                    ),
                                    if (s.difficulty != null) ...[
                                      const SizedBox(width: 16),
                                      _HistoryStat(
                                        label: 'Difficulty',
                                        value: s.difficulty!,
                                      ),
                                    ],
                                  ],
                                ),
                                if (s.triggerTypes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children:
                                        s.triggerTypes
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
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  t,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: _kBlue,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                                if (s.reflection?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    s.reflection!,
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
                      ),
            ),
          ],
        ),
      ),
    );
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
