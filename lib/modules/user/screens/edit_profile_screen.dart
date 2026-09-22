import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  String _accountType = 'normal';
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
    await FirebaseDatabase.instance.ref('users/$uid').get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _name = data['name'] ?? 'User';
        _nameController.text = data['name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _phoneController.text =
            (data['phone'] ?? '').toString().replaceAll('+91', '');
        _emailController.text = data['email'] ?? '';
        _accountType = data['accountType'] ?? 'normal';
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      // 1. Update basic fields
      await FirebaseDatabase.instance.ref('users/$uid').update({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
      });
      setState(() => _name = _nameController.text.trim());

      // 2. Email update
      final newEmail = _emailController.text.trim();
      if (newEmail != user.email && newEmail.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          _showError('Enter current password to change email');
          setState(() => _isSaving = false);
          return;
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.verifyBeforeUpdateEmail(newEmail);
        await FirebaseDatabase.instance
            .ref('users/$uid')
            .update({'email': newEmail});
        _showSuccess('Verification sent to $newEmail');
      }

      // 3. Password update
      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text.length < 6) {
          _showError('New password must be at least 6 characters');
          setState(() => _isSaving = false);
          return;
        }
        if (_currentPasswordController.text.isEmpty) {
          _showError('Enter current password to change password');
          setState(() => _isSaving = false);
          return;
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);
        _showSuccess('Password updated!');
        _newPasswordController.clear();
        _currentPasswordController.clear();
      }

      setState(() => _isEditing = false);
      _showSuccess('Profile updated successfully!');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Update failed');
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF1D9E75),
        ),
      );
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  InputDecoration _fieldDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + edit icon ────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  // Edit icon — bottom right of avatar
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isEditing = !_isEditing),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _isEditing
                              ? AppColors.primaryDark
                              : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _isEditing
                              ? Icons.close_rounded
                              : Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _accountType == 'seller'
                      ? '🏪 Seller'
                      : '👤 Normal User',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Basic Info ─────────────────────────────────────────────
            const Text(
              'BASIC INFO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: _fieldDeco('Full Name', Icons.person_outline_rounded),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _ageController,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              decoration: _fieldDeco('Age', Icons.cake_outlined),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _fieldDeco(
                'Phone Number',
                Icons.phone_outlined,
              ).copyWith(
                prefixText: '+91 ',
                counterText: '',
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'LOGIN DETAILS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              decoration:
              _fieldDeco('Email', Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _currentPasswordController,
              enabled: _isEditing,
              obscureText: _obscureCurrent,
              decoration: _fieldDeco(
                'Current Password',
                Icons.lock_outline_rounded,
              ).copyWith(
                helperText:
                _isEditing ? 'Required only if changing email/password' : null,
                helperStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
                suffixIcon: _isEditing
                    ? IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  onPressed: () => setState(
                        () => _obscureCurrent = !_obscureCurrent,
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _newPasswordController,
              enabled: _isEditing,
              obscureText: _obscureNew,
              decoration: _fieldDeco(
                'New Password (optional)',
                Icons.lock_reset_outlined,
              ).copyWith(
                suffixIcon: _isEditing
                    ? IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                )
                    : null,
              ),
            ),

            // ── Save Changes button — only when editing ───────────────
            if (_isEditing) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}