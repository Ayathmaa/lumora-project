import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

const _kBg = Color(0xFFC8DCF0);
const _kNavy = Color(0xFF1A3A5C);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);

class EditProfileScreen extends StatefulWidget {
  final String currentUsername;

  const EditProfileScreen({super.key, required this.currentUsername});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isSaving = false;
  File? _imageFile;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
    _existingPhotoUrl = user?.photoURL;
    _usernameCtrl.text = widget.currentUsername;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? newUrl = _existingPhotoUrl;

      // Upload to Storage if there's a new file
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'avatars/${user.uid}.jpg',
        );
        final bytes = await _imageFile!.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        newUrl = await ref.getDownloadURL();
      }

      await _auth.updateUserProfile(
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        photoURL: newUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop(newUrl); // Signal calling screen to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
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
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: _kNavy, fontWeight: FontWeight.bold),
        ),
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: _kBg,
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : (_existingPhotoUrl != null &&
                                          _existingPhotoUrl!.isNotEmpty
                                      ? NetworkImage(_existingPhotoUrl!)
                                      : null),
                          child:
                              (_imageFile == null &&
                                      (_existingPhotoUrl == null ||
                                          _existingPhotoUrl!.isEmpty))
                                  ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: _kNavy,
                                  )
                                  : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _kBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Name',
                      style: TextStyle(
                        color: _kNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kBg.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'AnoChat Username',
                      style: TextStyle(
                        color: _kNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kBg.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v.length < 3) return 'Too short';
                      if (RegExp(r'[^a-zA-Z0-9_]').hasMatch(v))
                        return 'No special characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isSaving
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
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
