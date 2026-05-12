import 'package:flutter/material.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kIconBg = Color(0xFFD6ECFA);
const _kBlue = Color(0xFF6BAED4);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'May 12, 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PolicyHeader(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              const _PolicyIntro(),
              const SizedBox(height: 12),
              const _PolicySection(
                title: '1. What Lumora does',
                body:
                    'Lumora helps you track mood, write CBT journal entries, practice ERP sessions, complete breathing exercises, watch guided meditations, build habit-free streaks, view progress insights, connect with an accountability partner, and participate in AnoChat community posts. Lumora is not a medical provider, emergency service, or replacement for professional care.',
              ),
              const _PolicySection(
                title: '2. Information we collect',
                body:
                    'We collect the information you provide when you create or use an account, including name, email address, username, optional age group, profile photo, password credentials handled by Firebase Authentication, and Google sign-in information if you choose Google login. Guest accounts store a username and anonymous account identifier.',
              ),
              const _PolicySection(
                title: '3. Wellness and activity data',
                body:
                    'Lumora saves wellness activity you enter or generate in the app, such as daily mood scores, CBT journal answers, pre- and post-anxiety levels, ERP session duration, ERP triggers, ERP reflections, meditation history, breathing exercise history, habit tracker names and marked dates, XP, streaks, progress timeline events, and derived charts or insights.',
              ),
              const _PolicySection(
                title: '4. Community and partner data',
                body:
                    'AnoChat posts include your selected anonymous username, post content, category, level display, reactions, and timestamps. Other Lumora users can see visible AnoChat posts. If you use Partner features, Lumora stores invites, partner connections, and sharing preferences. Your partner only sees the progress information you choose to share, such as anxiety remaining, daily mood, or journey calendar data.',
              ),
              const _PolicySection(
                title: '5. Notifications and device features',
                body:
                    'If you allow notifications, Lumora schedules daily mood reminders on your device. Notification actions can save a mood score to your account. If you upload a profile photo, the app uses your selected image and stores it in Firebase Storage.',
              ),
              const _PolicySection(
                title: '6. How we use information',
                body:
                    'We use your information to create and secure your account, save your progress, show history and charts, calculate streaks and XP, personalize app features, enable partner sharing you choose, display AnoChat posts and reactions, send reminders, maintain safety and moderation, troubleshoot issues, and improve Lumora.',
              ),
              const _PolicySection(
                title: '7. How information is shared',
                body:
                    'We do not sell your personal information. Information may be shared with service providers that operate Lumora, including Firebase Authentication, Cloud Firestore, Firebase Storage, Cloud Functions, Google Sign-In, and local notification services. AnoChat content is shared with other app users, partner data is shared according to your settings, and information may be disclosed if required by law, to protect rights and safety, or to prevent abuse.',
              ),
              const _PolicySection(
                title: '8. Storage and security',
                body:
                    'Lumora stores account and app data in Firebase services. We use Firebase authentication and database security controls to help protect user data. No app or internet service can guarantee perfect security, so avoid entering information you would not want stored in a digital service.',
              ),
              const _PolicySection(
                title: '9. Your choices',
                body:
                    'You can choose whether to create a full account, continue as a guest, use Google sign-in, upload a profile photo, enable notifications, post in AnoChat, connect a partner, or share partner progress data. You can edit your profile, change your password, remove a partner, change partner sharing preferences, delete your own AnoChat posts, and log out from the Profile page.',
              ),
              const _PolicySection(
                title: '10. Data retention',
                body:
                    'Lumora keeps your account and activity data while your account is active or as needed to provide the app. Some data may remain in backups or logs for a limited time. If you want your account or stored wellness data deleted, contact the app owner or support contact for Lumora.',
              ),
              const _PolicySection(
                title: '11. Children',
                body:
                    'Lumora is not intended for children under 13. If you believe a child under 13 has provided personal information, contact the app owner so the information can be reviewed and deleted where appropriate.',
              ),
              const _PolicySection(
                title: '12. Sensitive information',
                body:
                    'Mood, anxiety, ERP, journal, habit, and community content may reveal sensitive information about your mental health or personal life. Use Lumora only if you are comfortable storing this information in the app. Do not use AnoChat or partner sharing for information you want to keep private.',
              ),
              const _PolicySection(
                title: '13. International processing',
                body:
                    'Lumora uses cloud service providers, so your information may be processed and stored in countries or regions outside where you live. Those places may have different data protection laws.',
              ),
              const _PolicySection(
                title: '14. Changes to this policy',
                body:
                    'We may update this Privacy Policy as Lumora changes. The date at the top shows when this version was last updated. Continued use of Lumora after an update means the updated policy applies.',
              ),
              const _PolicySection(
                title: '15. Contact',
                body:
                    'For privacy questions, account deletion, or data requests, contact the Lumora app owner or the support channel provided with the app.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _PolicyHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
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
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Last updated ${PrivacyPolicyScreen._lastUpdated}',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyIntro extends StatelessWidget {
  const _PolicyIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, color: _kBlue, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This policy explains what Lumora collects, why it is used, and the choices you have when using the app.',
              style: TextStyle(fontSize: 13, color: _kSubtitle, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.article_outlined, color: _kBlue, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kNavy,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: _kSubtitle,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
