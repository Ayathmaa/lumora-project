import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/services/gamification_service.dart';
import 'package:lumora_flutter/services/gamification_utils.dart';
import 'package:lumora_flutter/screens/login_screen.dart';
import 'package:lumora_flutter/screens/upgrade_account_screen.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kIconBg = Color(0xFFD6ECFA);
const _kBlue = Color(0xFF6BAED4);
const _kBarTrack = Color(0xFFE0EAF4);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final username = await _authService.getUsername(uid);
    if (mounted && username != null) {
      setState(() => _username = username);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w800, color: _kNavy),
            ),
            content: const Text(
              'Are you sure you want to log out?',
              style: TextStyle(color: _kSubtitle),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: _kSubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log Out',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;
    final displayName =
        isAnonymous
            ? 'Guest'
            : (user?.displayName?.isNotEmpty == true
                ? user!.displayName!
                : 'Aurora');
    final email = isAnonymous ? '' : (user?.email ?? '');
    final initials =
        displayName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .take(2)
            .join();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                    ),
                  ),
                  Text(
                    'Your account details',
                    style: TextStyle(fontSize: 12, color: _kSubtitle),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Avatar + name ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar circle
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6BAED4), Color(0xFF1A3A5C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!isAnonymous)
                      Text(
                        email,
                        style: const TextStyle(fontSize: 14, color: _kSubtitle),
                      ),
                    if (_username != null && _username!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF5FB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFB8D8EC),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.alternate_email,
                              size: 13,
                              color: _kBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _username!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kBlue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '· AnoChat',
                              style: TextStyle(fontSize: 11, color: _kSubtitle),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    StreamBuilder<GamificationStats>(
                      stream: GamificationService().getStatsStream(),
                      builder: (context, snapshot) {
                        final stats =
                            snapshot.data ?? const GamificationStats();
                        final levelDisplay = GamificationUtils.getLevelDisplay(
                          stats.xp,
                        );
                        final progress = GamificationUtils.getProgress(
                          stats.xp,
                        );
                        final nextLimit = GamificationUtils.getNextXpLimit(
                          stats.xp,
                        );

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _kIconBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                levelDisplay,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // XP bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: _kBarTrack,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _kBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${stats.xp} / $nextLimit XP',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kSubtitle,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Upgrade banner (anonymous users only) ─────────────────────
              if (isAnonymous) ...[
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UpgradeAccountScreen(),
                        ),
                      ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6BAED4), Color(0xFF1A3A5C)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create a full account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Save your progress and access all features.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xCCFFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Account settings ──────────────────────────────────────────
              _SectionCard(
                title: 'Account',
                items: [
                  _SettingRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: () {},
                  ),
                  _SettingRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    onTap: () {},
                  ),
                  _SettingRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Preferences ───────────────────────────────────────────────
              _SectionCard(
                title: 'Preferences',
                items: [
                  _SettingRow(
                    icon: Icons.palette_outlined,
                    label: 'Appearance',
                    onTap: () {},
                  ),
                  _SettingRow(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    onTap: () {},
                  ),
                  _SettingRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Logout button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lumora v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _kSubtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section card helper ───────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<_SettingRow> items;

  const _SectionCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kSubtitle,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }
}

// ── Individual setting row ────────────────────────────────────────────────
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kIconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _kBlue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kNavy,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _kSubtitle,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
