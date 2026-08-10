import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../main.dart';

class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipcodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _selectedDistrict;

  final List<String> _districts = [
    'Ariyalur',
    'Chengalpattu',
    'Chennai',
    'Coimbatore',
    'Cuddalore',
    'Dharmapuri',
    'Dindigul',
    'Erode',
    'Kallakurichi',
    'Kancheepuram',
    'Kanyakumari',
    'Karur',
    'Krishnagiri',
    'Madurai',
    'Mayiladuthurai',
    'Nagapattinam',
    'Namakkal',
    'Nilgiris',
    'Perambalur',
    'Pudukkottai',
    'Ramanathapuram',
    'Ranipet',
    'Salem',
    'Sivaganga',
    'Tenkasi',
    'Thanjavur',
    'Theni',
    'Thoothukudi',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tirupathur',
    'Tiruppur',
    'Tiruvallur',
    'Tiruvannamalai',
    'Tiruvarur',
    'Vellore',
    'Viluppuram',
    'Virudhunagar',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }

  // ============================================================
  // CREATE ADMIN
  // ============================================================

  Future<void> _createAdmin() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final zipcode = _zipcodeController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        city.isEmpty ||
        zipcode.isEmpty ||
        _selectedDistrict == null) {
      _showMessage('Please fill all required fields!', AppColors.error);
      return;
    }

    if (phone.length != 10) {
      _showMessage(
        'Please enter a valid 10-digit phone number.',
        AppColors.error,
      );
      return;
    }

    if (zipcode.length != 6) {
      _showMessage('Please enter a valid 6-digit zipcode.', AppColors.error);
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.', AppColors.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    FirebaseApp? tempApp;

    try {
      // ----------------------------------------------------------
      // Secondary Firebase App
      // This keeps Super Admin logged in.
      // ----------------------------------------------------------

      tempApp = await Firebase.initializeApp(
        name: 'TempAdminCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // ----------------------------------------------------------
      // Create Firebase Auth account
      // ----------------------------------------------------------

      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // ----------------------------------------------------------
      // Sign out temporary account and delete temporary app
      // ----------------------------------------------------------

      await tempAuth.signOut();
      await tempApp.delete();
      tempApp = null;

      // ----------------------------------------------------------
      // Save Admin Details
      // ----------------------------------------------------------

      await FirebaseDatabase.instance.ref('admins/$uid').set({
        'name': name,
        'email': email,
        'phone': '+91$phone',
        'address': address,
        'city': city,
        'zipcode': zipcode,
        'role': 'admin',
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      _showMessage(
        'Business Admin Created Successfully!',
        const Color(0xFF1D9E75),
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }

      String message = 'Something went wrong.';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered!';
          break;

        case 'weak-password':
          message = 'Password must be at least 6 characters!';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email!';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection.';
          break;

        default:
          message = e.message ?? 'Unable to create admin.';
      }

      if (mounted) {
        _showMessage(message, AppColors.error);
      }
    } catch (e) {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }

      if (mounted) {
        _showMessage('Error: ${e.toString()}', AppColors.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // FIELD DECORATION
  // ============================================================

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return InputDecoration(
      labelText: label,

      labelStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        fontSize: 13,
      ),

      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),

      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: isDark ? AppColors.darkSurface : AppColors.surfaceVariant,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(bool isDark, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),

        const SizedBox(width: 9),

        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: .8,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION CONTAINER
  // ============================================================

  Widget _sectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(isDark, title, icon),

          const SizedBox(height: 15),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF5F6FA),

      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,

        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          'Create Business Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // HEADER INFO
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withOpacity(.12)
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Business Admin',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.primaryDark,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Create a secure login account and business admin profile.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // PERSONAL DETAILS
                  // ==================================================
                  _sectionCard(
                    isDark: isDark,
                    title: 'PERSONAL DETAILS',
                    icon: Icons.person_outline_rounded,
                    children: [
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _fieldDecoration(
                          context,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: _fieldDecoration(
                          context,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                        ).copyWith(prefixText: '+91 ', counterText: ''),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // ADDRESS
                  // ==================================================
                  _sectionCard(
                    isDark: isDark,
                    title: 'ADDRESS DETAILS',
                    icon: Icons.location_on_outlined,
                    children: [
                      TextField(
                        controller: _addressController,
                        maxLines: 3,
                        minLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _fieldDecoration(
                          context,
                          label: 'Address',
                          icon: Icons.home_outlined,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // DISTRICT
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        isExpanded: true,
                        isDense: true,
                        menuMaxHeight: 300,

                        decoration: _fieldDecoration(
                          context,
                          label: 'District',
                          icon: Icons.location_city_outlined,
                        ),

                        hint: Text(
                          'Select District',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textHint,
                          ),
                        ),

                        dropdownColor: isDark
                            ? AppColors.darkSurface
                            : Colors.white,

                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),

                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                        ),

                        items: _districts
                            .map(
                              (district) => DropdownMenuItem<String>(
                                value: district,
                                child: Text(district),
                              ),
                            )
                            .toList(),

                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value;

                            _cityController.text = value ?? '';
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _zipcodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: _fieldDecoration(
                          context,
                          label: 'Zipcode',
                          icon: Icons.pin_drop_outlined,
                        ).copyWith(counterText: ''),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // LOGIN DETAILS
                  // ==================================================
                  _sectionCard(
                    isDark: isDark,
                    title: 'LOGIN DETAILS',
                    icon: Icons.lock_outline_rounded,
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: _fieldDecoration(
                          context,
                          label: 'Email Address',
                          icon: Icons.mail_outline_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _fieldDecoration(
                          context,
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
                              size: 19,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textHint,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            'Password must contain at least 6 characters.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // CREATE BUTTON
                  // ==================================================
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createAdmin,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(
                          .55,
                        ),
                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: _isLoading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_alt_1_rounded, size: 20),

                                SizedBox(width: 9),

                                Text(
                                  'Create Business Admin',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // BOTTOM NOTE
                  // ==================================================
                  Text(
                    'The Business Admin can use the email and password above to login.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textHint,
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
