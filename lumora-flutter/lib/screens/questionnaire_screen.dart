import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _kNavy = Color(0xFF1A3A5C);
const _kBackground = Color(0xFFC8DCF0);
const _kSubtitle = Color(0xFF7BA7BF);
const _kFieldFill = Color(0xFFEEF5FB);
const _kButton = Color(0xFF6BAED4);
const _kDanger = Color(0xFFE57373);

class QuestionnaireScreen extends StatefulWidget {
  final Widget? nextScreen;
  final bool deleteAccountOnFail;

  const QuestionnaireScreen({
    super.key,
    this.nextScreen,
    this.deleteAccountOnFail = false,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final Map<int, int> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'section': 'Section A – Emotional Severity',
      'q':
          '01. In the past 2 weeks, how often have you felt extremely hopeless or overwhelmed?',
      'type': 'scale',
    },
    {
      'section': 'Section A – Emotional Severity',
      'q':
          '02. In the past 2 weeks, how often have your emotions felt out of control?',
      'type': 'scale',
    },
    {
      'section': 'Section A – Emotional Severity',
      'q':
          '03. Have your thoughts caused you severe distress that feels unbearable?',
      'type': 'scale',
    },
    {
      'section': 'Section B – Daily Functioning',
      'q':
          '04. Has your mental health stopped you from attending school/work regularly?',
      'type': 'scale',
    },
    {
      'section': 'Section B – Daily Functioning',
      'q':
          '05. Are you unable to complete basic daily tasks (eating, hygiene, sleeping)?',
      'type': 'scale',
    },
    {
      'section': 'Section B – Daily Functioning',
      'q': '06. Have your symptoms caused serious problems in relationships?',
      'type': 'scale',
    },
    {
      'section': 'Section C – OCD / Anxiety Intensity',
      'q':
          '07. Do you spend more than 1 hour per day stuck in intrusive thoughts or compulsions?',
      'type': 'scale',
    },
    {
      'section': 'Section C – OCD / Anxiety Intensity',
      'q': '08. Do you feel unable to resist compulsions at all?',
      'type': 'scale',
    },
    {
      'section': 'Section C – OCD / Anxiety Intensity',
      'q':
          '09. Does anxiety frequently cause panic attacks or physical shutdown?',
      'type': 'scale',
    },
    {
      'section': 'Section D – Risk Screening',
      'q': '10. Have you recently had thoughts of harming yourself?',
      'type': 'yesno',
    },
    {
      'section': 'Section D – Risk Screening',
      'q': '11. Have you recently felt that life is not worth living?',
      'type': 'yesno',
    },
    {
      'section': 'Section D – Risk Screening',
      'q': '12. Have you ever made a recent plan to hurt yourself?',
      'type': 'yesno',
    },
    {
      'section': 'Section D – Risk Screening',
      'q': '13. Are you currently in a situation where you feel unsafe?',
      'type': 'yesno',
    },
    {
      'section': 'Section E – Support & Stability',
      'q':
          '14. Do you currently have access to professional mental health support?',
      'type': 'yesno',
    },
    {
      'section': 'Section E – Support & Stability',
      'q': '15. Do you have at least one trusted person you can talk to?',
      'type': 'yesno',
    },
  ];

  void _nextPage() {
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _evaluateResults();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _evaluateResults() async {
    bool highRiskD = false;
    for (int i = 9; i <= 12; i++) {
      if (_answers[i] == 1) {
        highRiskD = true;
        break;
      }
    }

    int scoreA = (_answers[0] ?? 0) + (_answers[1] ?? 0) + (_answers[2] ?? 0);
    int scoreB = (_answers[3] ?? 0) + (_answers[4] ?? 0) + (_answers[5] ?? 0);

    bool highRiskAB = (scoreA + scoreB) >= 14;
    bool severeFunctioning = scoreB >= 7;

    if (highRiskD || highRiskAB || severeFunctioning) {
      if (widget.deleteAccountOnFail) {
        try {
          await FirebaseAuth.instance.currentUser?.delete();
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HighRiskScreen()),
      );
    } else {
      if (widget.nextScreen != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => widget.nextScreen!),
        );
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading:
            _currentIndex > 0
                ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: _kNavy),
                  onPressed: _prevPage,
                )
                : IconButton(
                  icon: const Icon(Icons.close, color: _kNavy),
                  onPressed: () {
                    if (widget.deleteAccountOnFail) {
                      try {
                        FirebaseAuth.instance.currentUser?.delete();
                      } catch (_) {}
                    }
                    Navigator.pop(context);
                  },
                ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _questions.length,
                      backgroundColor: _kFieldFill,
                      valueColor: const AlwaysStoppedAnimation<Color>(_kButton),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      color: _kNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  final isScale = q['type'] == 'scale';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index == 0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _kFieldFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Lumora is designed for mild to moderate stress, anxiety, and OCD-related challenges.\n\nIf you are experiencing severe distress or crisis, professional support may be more appropriate.",
                              style: TextStyle(
                                color: _kNavy,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          q['section'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _kButton,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q['q'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kNavy,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (isScale) ...[
                          _buildOption(index, 0, 'Not at all'),
                          const SizedBox(height: 12),
                          _buildOption(index, 1, 'Occasionally / Rarely'),
                          const SizedBox(height: 12),
                          _buildOption(index, 2, 'Often / Sometimes'),
                          const SizedBox(height: 12),
                          _buildOption(index, 3, 'Almost every day'),
                        ] else ...[
                          _buildOption(index, 1, 'Yes'),
                          const SizedBox(height: 12),
                          _buildOption(index, 0, 'No'),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: _kBackground,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: ElevatedButton(
          onPressed: _answers.containsKey(_currentIndex) ? _nextPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kButton,
            disabledBackgroundColor: _kFieldFill,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: Text(
            _currentIndex == _questions.length - 1
                ? 'Complete Assessment'
                : 'Continue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  _answers.containsKey(_currentIndex)
                      ? Colors.white
                      : _kSubtitle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(int questionIndex, int value, String label) {
    final isSelected = _answers[questionIndex] == value;

    return InkWell(
      onTap: () {
        setState(() => _answers[questionIndex] = value);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted &&
              _answers.containsKey(_currentIndex) &&
              _currentIndex == questionIndex) {
            _nextPage();
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? _kFieldFill : Colors.white,
          border: Border.all(
            color: isSelected ? _kButton : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _kButton : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kButton,
                          ),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? _kNavy : _kNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HighRiskScreen extends StatelessWidget {
  const HighRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.favorite, size: 80, color: _kDanger),
              const SizedBox(height: 32),
              const Text(
                'We care about your safety.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Based on your responses, Lumora may not be the right level of support for you at this time.\n\nWe strongly encourage you to seek professional help. You deserve proper care and support.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5, color: _kSubtitle),
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kFieldFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB8D8EC)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Emergency Help',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kDanger,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Global Emergency Contacts:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _kNavy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Call local emergency services (911, 999, 112)\nGo to your nearest emergency room\n',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _kNavy, height: 1.4),
                    ),
                    Text(
                      'US: Call or text 988\nUK: 111 or 999\nAus: 111 or 000',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _kNavy, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Return to Welcome',
                    style: TextStyle(
                      fontSize: 16,
                      color: _kButton,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
