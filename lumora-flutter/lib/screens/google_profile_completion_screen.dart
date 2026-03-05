import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/screens/main_shell.dart';

// Design constants (matching app theme)
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF7BA7BF);
const _kFieldFill = Color(0xFFEEF5FB);
const _kIconHint = Color(0xFFA8C4D8);
const _kButton = Color(0xFF6BAED4);
const _kBackground = Color(0xFFC8DCF0);

const _ageGroups = [
  'Under 18',
  '18 – 24',
  '25 – 34',
  '35 – 44',
  '45 – 54',
  '55+',
];

final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

class GoogleProfileCompletionScreen extends StatefulWidget {
  final User googleUser;

  const GoogleProfileCompletionScreen({super.key, required this.googleUser});

  @override
  State<GoogleProfileCompletionScreen> createState() =>
      _GoogleProfileCompletionScreenState();
}

class _GoogleProfileCompletionScreenState
    extends State<GoogleProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _selectedAgeGroup;

  // Username availability state
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
    if (value.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
      });
      return;
    }
    if (!_usernameRegex.hasMatch(value)) {
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
      return const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(strokeWidth: 3, color: _kButton),
      );
    }
    if (_isUsernameAvailable == true) {
      return const Icon(
        Icons.check_circle_outline,
        color: Colors.green,
        size: 20,
      );
    }
    if (_isUsernameAvailable == false) {
      return const Icon(
        Icons.cancel_outlined,
        color: Colors.redAccent,
        size: 20,
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _complete() async {
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
      final user = widget.googleUser;
      await _authService.saveUserProfile(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        username: _usernameController.text.trim(),
        ageGroup: _selectedAgeGroup,
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

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kIconHint, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: _kIconHint, size: 20),
      suffixIcon:
          suffix != null
              ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffix,
              )
              : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: _kFieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB8D8EC), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB8D8EC), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kButton, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
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
                  const SizedBox(height: 28),

                  // Logo
                  Image.asset(
                    'assets/images/logo_v2.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),

                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: const Text(
                      'Lumora',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _kNavy,
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // White card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                        const Center(
                          child: Text(
                            'One Last Step!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _kNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Welcome, ${widget.googleUser.displayName?.split(' ').first ?? 'there'}! Set up your profile.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kSubtitle,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Username label
                        const Text(
                          'AnoChat Username',
                          style: TextStyle(
                            fontSize: 12,
                            color: _kSubtitle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          onChanged: _onUsernameChanged,
                          decoration: _fieldDecoration(
                            hint: 'e.g. calm_sky_21',
                            prefixIcon: Icons.alternate_email,
                            suffix: _usernameStatusIcon(),
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
                        const Text(
                          'This is how you\'ll appear in AnoChat. Keep it anonymous.',
                          style: TextStyle(fontSize: 11, color: _kSubtitle),
                        ),
                        const SizedBox(height: 18),

                        // Age Group label
                        const Text(
                          'Age Group (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: _kSubtitle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Age Group dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kFieldFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFB8D8EC),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedAgeGroup,
                              hint: const Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: _kIconHint,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Select your age group',
                                    style: TextStyle(
                                      color: _kIconHint,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: _kIconHint,
                              ),
                              isExpanded: true,
                              style: const TextStyle(
                                color: _kNavy,
                                fontSize: 14,
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              items:
                                  _ageGroups
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(g),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _selectedAgeGroup = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _complete,
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
                                      'Continue',
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
