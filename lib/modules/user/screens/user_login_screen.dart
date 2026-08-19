import 'package:digitalads/modules/user/screens/user_home_screen.dart';
import 'package:digitalads/modules/user/screens/user_register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../admin/screens/bloc/admin_home_screen.dart';
import '../../super_admin/screens/super_admin_dashboard.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpLoading = false;
  bool _obscurePassword = true;

  // This screen is intentionally always light-styled (branded background +
  // white card), regardless of the app's dark-mode setting elsewhere.
  static const _fieldTextColor = Color(0xFF1A1A2E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      _showMessage('Enter a valid 10-digit phone number');
      return;
    }

    setState(() {
      _isOtpLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } catch (e) {
            debugPrint('Auto verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _isOtpLoading = false;
          });
          _showMessage(e.message ?? 'OTP verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _isOtpLoading = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OtpScreen(verificationId: verificationId, phoneNumber: phone),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          setState(() {
            _isOtpLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOtpLoading = false;
      });
      _showMessage('Unable to send OTP. Please try again.');
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please fill all fields!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      debugPrint('================================');
      debugPrint('LOGIN SUCCESS');
      debugPrint('UID: $uid');
      debugPrint('EMAIL: ${userCredential.user!.email}');
      debugPrint('================================');

      final adminSnapshot =
      await FirebaseDatabase.instance.ref('admins/$uid').get();

      debugPrint('Admin exists: ${adminSnapshot.exists}');

      if (adminSnapshot.exists) {
        final adminData =
        Map<String, dynamic>.from(adminSnapshot.value as Map);

        debugPrint('ADMIN DATA: $adminData');

        final status =
        (adminData['status'] ?? 'active').toString().toLowerCase();

        if (status == 'inactive') {
          await FirebaseAuth.instance.signOut();
          _showMessage('Your business admin account has been deactivated.');
          return;
        }

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
              (route) => false,
        );

        return;
      }

      final userSnapshot =
      await FirebaseDatabase.instance.ref('users/$uid').get();

      debugPrint('User exists: ${userSnapshot.exists}');

      if (userSnapshot.exists) {
        final userData =
        Map<String, dynamic>.from(userSnapshot.value as Map);

        debugPrint('USER DATA: $userData');

        final status =
        (userData['status'] ?? 'active').toString().toLowerCase();

        if (status == 'inactive') {
          await FirebaseAuth.instance.signOut();
          _showMessage('Your account has been deactivated.');
          return;
        }

        final role = (userData['role'] ?? 'user').toString().toLowerCase();

        debugPrint('USER ROLE: $role');

        if (role == 'super admin' || role == 'super_admin') {
          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
                (route) => false,
          );

          return;
        }

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
              (route) => false,
        );

        return;
      }

      await FirebaseAuth.instance.signOut();
      _showMessage('User account details not found.');
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code}');

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }

      _showMessage(message);
    } catch (e) {
      debugPrint('Login error: $e');
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF85859B)),
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(.48)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'DigitalAds',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Local ads, near you',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 38),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.96),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.15),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Sign in to continue to DigitalAds',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF777791),
                          ),
                        ),
                        const SizedBox(height: 25),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: _fieldTextColor),
                          cursorColor: AppColors.primary,
                          decoration: _inputDecoration(
                            label: 'Email address',
                            icon: Icons.mail_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: _fieldTextColor),
                          cursorColor: AppColors.primary,
                          onSubmitted: (_) {
                            if (!_isLoading) {
                              _login();
                            }
                          },
                          decoration: _inputDecoration(
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary
                                  .withOpacity(.55),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF85859B),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Sign in with phone',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF33334A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: const TextStyle(color: _fieldTextColor),
                          cursorColor: AppColors.primary,
                          decoration: _inputDecoration(
                            label: 'Phone number',
                            icon: Icons.phone_outlined,
                          ).copyWith(prefixText: '+91  ', counterText: ''),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isOtpLoading ? null : _sendOtp,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              disabledForegroundColor: AppColors.primary
                                  .withOpacity(.5),
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: _isOtpLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.sms_outlined, size: 18),
                            label: Text(
                              _isOtpLoading ? 'Sending...' : 'Send OTP',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserRegisterScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF777791),
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Register',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}