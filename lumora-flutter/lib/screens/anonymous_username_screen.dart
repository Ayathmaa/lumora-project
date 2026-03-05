import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/screens/main_shell.dart';
import 'package:lumora_flutter/screens/login_screen.dart';

// Design constants
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF7BA7BF);
const _kFieldFill = Color(0xFFEEF5FB);
const _kIconHint = Color(0xFFA8C4D8);
const _kButton = Color(0xFF6BAED4);
const _kBackground = Color(0xFFC8DCF0);

final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

class AnonymousUsernameScreen extends StatefulWidget {
  const AnonymousUsernameScreen({super.key});

  @override
  State<AnonymousUsernameScreen> createState() =>
      _AnonymousUsernameScreenState();
}

class _AnonymousUsernameScreenState extends State<AnonymousUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _usernameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    if (value.isEmpty || !_usernameRegex.hasMatch(value)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
      });
      return;
    }
    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final taken = await _authService.isUsernameTaken(value);
      if (mounted && _usernameController.text == value) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = !taken;
        });
      }
    });
  }

  Widget _usernameStatusIcon() {
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 3, color: _kButton),
        ),
      );
    }
    if (_isUsernameAvailable == true) {
      return const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
      );
    }
    if (_isUsernameAvailable == false) {
      return const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUsernameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose an available username'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = _authService.currentUser!.uid;
      await _authService.saveGuestProfile(
        uid: uid,
        username: _usernameController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, _kBackground],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () async {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _kNavy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logo
                  Image.asset(
                    'assets/images/logo_v2.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),

                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: const Text(
                      'Lumora',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kNavy,
                      ),
                    ),
                  ),

                  // ── Card ─────────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Guest badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5FB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFB8D8EC),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: _kButton,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Continuing as Guest',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kButton,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Center(
                          child: Text(
                            'Pick your AnoChat name',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _kNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'This is how others will see you in AnoChat.',
                            style: TextStyle(fontSize: 13, color: _kSubtitle),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          onChanged: _onUsernameChanged,
                          decoration: InputDecoration(
                            hintText: 'AnoChat Username (e.g. calm_sky_21)',
                            hintStyle: const TextStyle(
                              color: _kIconHint,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.alternate_email,
                              color: _kIconHint,
                              size: 20,
                            ),
                            suffixIcon: _usernameStatusIcon(),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            filled: true,
                            fillColor: _kFieldFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFB8D8EC),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFB8D8EC),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _kButton,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please choose a username';
                            }
                            if (!_usernameRegex.hasMatch(v)) {
                              return 'Letters, numbers & underscores only (3–20 chars)';
                            }
                            if (_isUsernameAvailable == false) {
                              return 'Username is already taken';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Visible only in AnoChat — keep it anonymous.',
                            style: TextStyle(fontSize: 11, color: _kSubtitle),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kButton,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Text(
                                      'Enter Lumora',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Warning about data loss
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFFE6A817),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guest data is tied to this device. Create a full account anytime from your profile to keep your progress safe.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7A5800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
