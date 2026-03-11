import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/journal_service.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kIconBg = Color(0xFFD6ECFA);
const _kBlue = Color(0xFF6BAED4);
const _kFieldFill = Color(0xFFEEF5FB);
const _kBorder = Color(0xFFB8D8EC);

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final List<TextEditingController> _controllers = List.generate(
    8,
    (_) => TextEditingController(),
  );
  double _emotionIntensity = 5;
  double _postAnxiety = 5;
  bool _isSaving = false;

  final _journalService = JournalService();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final answers = <int, String>{
        for (int i = 0; i < 8; i++) i + 1: _controllers[i].text.trim(),
      };
      final journalNumber = await _journalService.saveCbtEntry(
        answers: answers,
        postAnxietyLevel: _postAnxiety.round(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Journal #$journalNumber saved successfully!'),
          backgroundColor: _kBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      // Clear fields after save
      for (final c in _controllers) {
        c.clear();
      }
      setState(() {
        _emotionIntensity = 5;
        _postAnxiety = 5;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildQuestion(
                    1,
                    Icons.bolt_rounded,
                    'What happened today that triggered this thought?',
                    'Describe the situation or event that started this...',
                    _controllers[0],
                  ),
                  const SizedBox(height: 12),
                  _buildQuestion(
                    2,
                    Icons.psychology_rounded,
                    'What negative thought came to your mind?',
                    'Write the exact thought as it appeared...',
                    _controllers[1],
                  ),
                  const SizedBox(height: 12),
                  _buildEmotionQuestion(),
                  const SizedBox(height: 12),
                  _buildQuestion(
                    4,
                    Icons.check_circle_outline_rounded,
                    'What evidence supports this thought?',
                    'List any facts that seem to back up this thought...',
                    _controllers[3],
                  ),
                  const SizedBox(height: 12),
                  _buildQuestion(
                    5,
                    Icons.cancel_outlined,
                    'What evidence does NOT support this thought?',
                    'What facts or experiences contradict this thought?',
                    _controllers[4],
                  ),
                  const SizedBox(height: 12),
                  _buildQuestion(
                    6,
                    Icons.lightbulb_outline_rounded,
                    'Is there another way to look at this situation?',
                    'Try to see it from a different angle or perspective...',
                    _controllers[5],
                  ),
                  const SizedBox(height: 12),
                  _buildQuestion(
                    7,
                    Icons.people_outline_rounded,
                    'What would you tell a friend in the same situation?',
                    'Imagine your best friend shared this with you...',
                    _controllers[6],
                  ),
                  const SizedBox(height: 12),
                  _buildFinalQuestion(),
                  const SizedBox(height: 20),
                  _buildPostAnxiety(),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                  const SizedBox(height: 12),
                  _buildHistoryLink(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A7CB8), Color(0xFF6BAED4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Guided CBT Journal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Text('✨', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 42),
            child: Text(
              'Re-align your thoughts gently, one step at a time.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildChip('8 questions'),
              const SizedBox(width: 8),
              _buildChip('~5 mins'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Standard question card ────────────────────────────────────────────────
  Widget _buildQuestion(
    int number,
    IconData icon,
    String question,
    String hint,
    TextEditingController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildNumberBadge(number),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _kBlue, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: _kNavy),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFACC8DF),
                fontSize: 13,
              ),
              filled: true,
              fillColor: _kFieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Q3 — Emotion + intensity slider ──────────────────────────────────────
  Widget _buildEmotionQuestion() {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildNumberBadge(3),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: _kBlue,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'What emotions did you feel? Rate the intensity below.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controllers[2],
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: _kNavy),
            decoration: InputDecoration(
              hintText: 'e.g. Anxious, sad, frustrated, overwhelmed...',
              hintStyle: const TextStyle(
                color: Color(0xFFACC8DF),
                fontSize: 13,
              ),
              filled: true,
              fillColor: _kFieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Intensity',
                style: TextStyle(
                  fontSize: 13,
                  color: _kSubtitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_emotionIntensity.round()} / 10',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kBlue,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kBlue,
              inactiveTrackColor: _kBorder,
              thumbColor: _kBlue,
              overlayColor: _kBlue.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _emotionIntensity,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _emotionIntensity = v),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: TextStyle(fontSize: 11, color: _kSubtitle)),
              Text(
                'Moderate',
                style: TextStyle(fontSize: 11, color: _kSubtitle),
              ),
              Text(
                'Intense',
                style: TextStyle(fontSize: 11, color: _kSubtitle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Q8 — Final dark card ──────────────────────────────────────────────────
  Widget _buildFinalQuestion() {
    return Container(
      decoration: BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '08 Final',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Write a balanced, healthier replacement thought.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controllers[7],
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'A kinder, more realistic way to see this situation...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Post-anxiety slider ───────────────────────────────────────────────────
  Widget _buildPostAnxiety() {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Post Anxiety Level',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${_postAnxiety.round()}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                    ),
                  ),
                  const TextSpan(
                    text: ' /10',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _kSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kBlue,
              inactiveTrackColor: _kBorder,
              thumbColor: _kBlue,
              overlayColor: _kBlue.withOpacity(0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _postAnxiety,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _postAnxiety = v),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: TextStyle(fontSize: 11, color: _kSubtitle)),
              Text('Mild', style: TextStyle(fontSize: 11, color: _kSubtitle)),
              Text(
                'Moderate',
                style: TextStyle(fontSize: 11, color: _kSubtitle),
              ),
              Text('High', style: TextStyle(fontSize: 11, color: _kSubtitle)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBlue.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            _isSaving
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                : const Text(
                  'Save Reflection',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
      ),
    );
  }

  // ── History link ──────────────────────────────────────────────────────────
  Widget _buildHistoryLink() {
    return Center(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.history_rounded, color: _kBlue, size: 18),
        label: const Text(
          'View Journal History',
          style: TextStyle(
            color: _kBlue,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Number badge ──────────────────────────────────────────────────────────
  Widget _buildNumberBadge(int number) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: _kIconBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          number.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kBlue,
          ),
        ),
      ),
    );
  }
}
