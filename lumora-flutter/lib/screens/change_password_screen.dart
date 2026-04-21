import 'package:flutter/material.dart';
import 'package:lumora_flutter/services/auth_service.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _newPassReCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isSaving = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureNewRe = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      await _auth.changePassword(
        currentPassword: _oldPassCtrl.text,
        newPassword: _newPassCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(color: _kNavy, fontWeight: FontWeight.bold)),
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kNavy),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Password', style: TextStyle(color: _kNavy, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _oldPassCtrl,
                    obscureText: _obscureOld,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kBg.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility, color: _kSubtitle),
                        onPressed: () => setState(() => _obscureOld = !_obscureOld),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('New Password', style: TextStyle(color: _kNavy, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kBg.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: _kSubtitle),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) => v!.length < 6 ? 'Must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Re-Type New Password', style: TextStyle(color: _kNavy, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPassReCtrl,
                    obscureText: _obscureNewRe,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kBg.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewRe ? Icons.visibility_off : Icons.visibility, color: _kSubtitle),
                        onPressed: () => setState(() => _obscureNewRe = !_obscureNewRe),
                      ),
                    ),
                    validator: (v) => v != _newPassCtrl.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
