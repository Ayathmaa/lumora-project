import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/screens/login_screen.dart';

const _kBg       = Color(0xFFC8DCF0);
const _kNavy     = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg   = Colors.white;
const _kIconBg   = Color(0xFFD6ECFA);
const _kBlue     = Color(0xFF6BAED4);
const _kBarTrack = Color(0xFFE0EAF4);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w800, color: _kNavy)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: _kSubtitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kSubtitle, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
    final user        = _authService.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Aurora';
    final email       = user?.email ?? '';
    final initials    = displayName
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
                  Text('Profile',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kNavy)),
                  Text('Your account details',
                      style: TextStyle(fontSize: 12, color: _kSubtitle)),
                ],
              ),
              const SizedBox(height: 28),

              // ── Avatar + name ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 10,
                        offset: Offset(0, 4)),
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
                              letterSpacing: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kNavy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 14, color: _kSubtitle),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kIconBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Level 3 – Blooming Soul',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kBlue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // XP bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        value: 0.32,
                        minHeight: 8,
                        backgroundColor: _kBarTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(_kBlue),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('320 / 1000 XP',
                        style: TextStyle(fontSize: 11, color: _kSubtitle)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats row ─────────────────────────────────────────────────
              Row(
                children: [
                  _MiniStat(label: 'Streak', value: '4 days',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF8C69)),
                  const SizedBox(width: 12),
                  _MiniStat(label: 'Sessions', value: '12',
                      icon: Icons.timer_rounded, color: _kBlue),
                  const SizedBox(width: 12),
                  _MiniStat(label: 'Journal', value: '9',
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF80C9A4)),
                ],
              ),
              const SizedBox(height: 16),

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
                  label: const Text('Log Out',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Lumora v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: _kSubtitle)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini stat tile ────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kNavy)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSubtitle)),
          ],
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
              color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kSubtitle,
                  letterSpacing: 0.5)),
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
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kNavy)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _kSubtitle, size: 20),
          ],
        ),
      ),
    );
  }
}
