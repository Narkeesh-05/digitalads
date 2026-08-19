//  import 'package:digitalads/modules/user/screens/user_login_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../app/theme.dart';
// import '../../../main.dart';
//
// class UserRegisterScreen extends StatefulWidget {
//   const UserRegisterScreen({super.key});
//
//   @override
//   State<UserRegisterScreen> createState() => _UserRegisterScreenState();
// }
//
// class _UserRegisterScreenState extends State<UserRegisterScreen> {
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _otpController = TextEditingController();
//   final _shopNameController = TextEditingController();
//   final _gstNumberController = TextEditingController();
//
//   String _accountType = 'normal';
//   String? _selectedCategory;
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _otpSent = false;
//   bool _otpVerified = false;
//   String _verificationId = '';
//
//   bool get _isSeller => _accountType == 'seller';
//
//   static const List<String> _categories = [
//     'Grocery & Supermarket',
//     'Electronics & Mobiles',
//     'Clothing & Fashion',
//     'Restaurant & Food',
//     'Bakery & Sweets',
//     'Salon & Beauty',
//     'Hardware & Tools',
//     'Pharmacy & Medical',
//     'Furniture & Home Decor',
//     'Automobile & Spares',
//     'Stationery & Books',
//     'Jewellery',
//     'Real Estate',
//     'Services (Repair, Tuition, etc.)',
//     'Other',
//   ];
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _phoneController.dispose();
//     _otpController.dispose();
//     _shopNameController.dispose();
//     _gstNumberController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _sendOtp() async {
//     if (_phoneController.text.isEmpty ||
//         _phoneController.text.length < 10) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter valid phone number!'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: '+91${_phoneController.text.trim()}',
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           setState(() {
//             _otpVerified = true;
//             _isLoading = false;
//           });
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           setState(() => _isLoading = false);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Verification failed: ${e.message}'),
//               backgroundColor: AppColors.error,
//             ),
//           );
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           setState(() {
//             _verificationId = verificationId;
//             _otpSent = true;
//             _isLoading = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('OTP Sent Successfully!'),
//               backgroundColor: Color(0xFF1D9E75),
//             ),
//           );
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           _verificationId = verificationId;
//         },
//       );
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }
//
//   Future<void> _verifyOtp() async {
//     if (_otpController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter OTP!'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId,
//         smsCode: _otpController.text.trim(),
//       );
//
//       // Just verify — don't sign in
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       await FirebaseAuth.instance.signOut();
//
//       setState(() {
//         _otpVerified = true;
//         _isLoading = false;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Phone Verified! ✅'),
//           backgroundColor: Color(0xFF1D9E75),
//         ),
//       );
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Invalid OTP!'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }
//
//   Future<void> _register() async {
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _passwordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all fields!'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }
//
//     if (_isSeller && _shopNameController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter your shop name!'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }
//
//     if (_isSeller && _selectedCategory == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select your business category!'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }
//
//     if (!_otpVerified) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please verify your phone number first!'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//
//       String uid = userCredential.user!.uid;
//
//       final userData = {
//         'name': _nameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'phone': '+91${_phoneController.text.trim()}',
//         'accountType': _accountType,
//         'points': 0,
//         'createdAt': DateTime.now().toIso8601String(),
//       };
//
//       if (_isSeller) {
//         userData['shopName'] = _shopNameController.text.trim();
//         userData['gstNumber'] = _gstNumberController.text.trim().toUpperCase();
//         userData['category'] = _selectedCategory ?? '';
//       }
//
//       await FirebaseDatabase.instance.ref('users/$uid').set(userData);
//
//       await FirebaseAuth.instance.signOut();
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Account Created Successfully! 🎉'),
//             backgroundColor: Color(0xFF1D9E75),
//           ),
//         );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const UserLoginScreen(),
//           ),
//               (route) => false,
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String message = 'Error occurred!';
//       if (e.code == 'email-already-in-use') {
//         message = 'This email is already registered! Please login.';
//       } else if (e.code == 'weak-password') {
//         message = 'Password must be at least 6 characters!';
//       } else if (e.code == 'invalid-email') {
//         message = 'Please enter a valid email!';
//       } else {
//         message = e.message ?? 'Error occurred!';
//       }
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: AppColors.error,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   InputDecoration _fieldDeco(String label, IconData icon, bool isDark,
//       {String? hint, String? suffixText}) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       labelStyle: TextStyle(
//         color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
//       ),
//       prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
//       suffixText: suffixText,
//       filled: true,
//       fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
//       ),
//     );
//   }
//
//   TextStyle _fieldTextStyle(bool isDark) {
//     return TextStyle(
//       color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = context.watch<ThemeProvider>().isDark;
//
//     return Scaffold(
//       backgroundColor:
//       isDark ? AppColors.darkBackground : AppColors.background,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 30),
//               Center(
//                 child: Container(
//                   width: 84,
//                   height: 84,
//                   decoration: const BoxDecoration(
//                     color: AppColors.primarySurface,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.person_add_alt_1_rounded,
//                     size: 40,
//                     color: AppColors.primary,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Center(
//                 child: Text(
//                   'Create Account',
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: isDark
//                         ? AppColors.darkTextPrimary
//                         : AppColors.textPrimary,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),
//               TextField(
//                 controller: _nameController,
//                 style: _fieldTextStyle(isDark),
//                 decoration: _fieldDeco(
//                     'Full Name', Icons.person_outline_rounded, isDark),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 style: _fieldTextStyle(isDark),
//                 decoration: _fieldDeco(
//                     'Email', Icons.mail_outline_rounded, isDark),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 style: _fieldTextStyle(isDark),
//                 decoration: _fieldDeco(
//                   'Password',
//                   Icons.lock_outline_rounded,
//                   isDark,
//                 ).copyWith(
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscurePassword
//                           ? Icons.visibility_off_outlined
//                           : Icons.visibility_outlined,
//                       color: AppColors.primary,
//                       size: 20,
//                     ),
//                     onPressed: () => setState(
//                             () => _obscurePassword = !_obscurePassword),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // ── Phone + OTP Section ──────────────────────────────
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _phoneController,
//                       keyboardType: TextInputType.phone,
//                       maxLength: 10,
//                       enabled: !_otpVerified,
//                       style: _fieldTextStyle(isDark),
//                       decoration: _fieldDeco(
//                         'Mobile Number',
//                         Icons.phone_outlined,
//                         isDark,
//                       ).copyWith(
//                         prefixText: '+91 ',
//                         counterText: '',
//                         suffixIcon: _otpVerified
//                             ? const Icon(Icons.check_circle,
//                             color: Color(0xFF1D9E75))
//                             : null,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   if (!_otpVerified)
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _sendOtp,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primary,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 16),
//                       ),
//                       child: const Text('Send OTP'),
//                     ),
//                 ],
//               ),
//
//               if (_otpSent && !_otpVerified) ...[
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _otpController,
//                         keyboardType: TextInputType.number,
//                         maxLength: 6,
//                         style: _fieldTextStyle(isDark),
//                         decoration: _fieldDeco(
//                           'Enter OTP',
//                           Icons.lock_outline_rounded,
//                           isDark,
//                         ).copyWith(counterText: ''),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _verifyOtp,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1D9E75),
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 16),
//                       ),
//                       child: const Text('Verify'),
//                     ),
//                   ],
//                 ),
//               ],
//
//               if (_otpVerified)
//                 Container(
//                   margin: const EdgeInsets.only(top: 8),
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF1D9E75).withOpacity(isDark ? .18 : .1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(Icons.check_circle_rounded,
//                           color: Color(0xFF1D9E75), size: 18),
//                       SizedBox(width: 8),
//                       Text(
//                         'Phone Verified!',
//                         style: TextStyle(
//                           color: Color(0xFF1D9E75),
//                           fontWeight: FontWeight.w600,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//               const SizedBox(height: 24),
//               Text(
//                 'ACCOUNT TYPE',
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 1,
//                   color: isDark
//                       ? AppColors.darkTextSecondary
//                       : AppColors.textHint,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               _accountTypeCard(
//                 isDark: isDark,
//                 icon: Icons.person_rounded,
//                 title: 'Normal User',
//                 subtitle: 'View & enquire about ads',
//                 value: 'normal',
//               ),
//               const SizedBox(height: 10),
//               _accountTypeCard(
//                 isDark: isDark,
//                 icon: Icons.storefront_rounded,
//                 title: 'Seller',
//                 subtitle: 'Upload & manage your own ads',
//                 value: 'seller',
//               ),
//
//               // ── Seller-only fields ────────────────────────────────
//               if (_isSeller) ...[
//                 const SizedBox(height: 20),
//                 Text(
//                   'BUSINESS DETAILS',
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: 1,
//                     color: isDark
//                         ? AppColors.darkTextSecondary
//                         : AppColors.textHint,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: _shopNameController,
//                   style: _fieldTextStyle(isDark),
//                   decoration: _fieldDeco(
//                       'Shop / Business Name', Icons.store_outlined, isDark),
//                 ),
//                 const SizedBox(height: 14),
//                 DropdownButtonFormField<String>(
//                   value: _selectedCategory,
//                   isExpanded: true,
//                   dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
//                   decoration: _fieldDeco(
//                       'Business Category', Icons.category_outlined, isDark),
//                   hint: Text(
//                     'Select Category',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: isDark
//                           ? AppColors.darkTextSecondary
//                           : AppColors.textHint,
//                     ),
//                   ),
//                   style: _fieldTextStyle(isDark),
//                   items: _categories
//                       .map((cat) => DropdownMenuItem(
//                     value: cat,
//                     child: Text(cat, overflow: TextOverflow.ellipsis),
//                   ))
//                       .toList(),
//                   onChanged: (value) =>
//                       setState(() => _selectedCategory = value),
//                 ),
//                 const SizedBox(height: 14),
//                 TextField(
//                   controller: _gstNumberController,
//                   textCapitalization: TextCapitalization.characters,
//                   maxLength: 15,
//                   style: _fieldTextStyle(isDark),
//                   decoration: _fieldDeco(
//                     'GST Number (optional)',
//                     Icons.receipt_long_outlined,
//                     isDark,
//                     hint: '22AAAAA0000A1Z5',
//                   ).copyWith(counterText: ''),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   'Sellers without GST can still register — this can be added later from Profile.',
//                   style: TextStyle(
//                     fontSize: 11.5,
//                     color: isDark
//                         ? AppColors.darkTextSecondary
//                         : AppColors.textHint,
//                   ),
//                 ),
//               ],
//
//               const SizedBox(height: 28),
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _register,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const SizedBox(
//                     width: 22,
//                     height: 22,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2.5,
//                     ),
//                   )
//                       : const Text(
//                     'Create Account',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Center(
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const UserLoginScreen(),
//                       ),
//                     );
//                   },
//                   child: const Text(
//                     'Already have an account? Login',
//                     style: TextStyle(color: AppColors.primary),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _accountTypeCard({
//     required bool isDark,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required String value,
//   }) {
//     final isSelected = _accountType == value;
//
//     return InkWell(
//       onTap: () => setState(() => _accountType = value),
//       borderRadius: BorderRadius.circular(14),
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.primarySurface
//               : (isDark ? AppColors.darkSurface : Colors.white),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isSelected
//                 ? AppColors.primary
//                 : (isDark ? AppColors.darkBorder : AppColors.border),
//             width: isSelected ? 1.5 : 0.8,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? AppColors.primary
//                     : AppColors.primarySurface,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(
//                 icon,
//                 color: isSelected ? Colors.white : AppColors.primary,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 14.5,
//                       fontWeight: FontWeight.w600,
//                       color: isDark
//                           ? AppColors.darkTextPrimary
//                           : AppColors.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: isDark
//                           ? AppColors.darkTextSecondary
//                           : AppColors.textSecondary,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Radio<String>(
//               value: value,
//               groupValue: _accountType,
//               activeColor: AppColors.primary,
//               onChanged: (v) => setState(() => _accountType = v!),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:digitalads/modules/user/screens/seller_document_upload.dart';
import 'package:digitalads/modules/user/screens/user_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../main.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _shopNameController = TextEditingController();

  String _accountType = 'normal';
  String? _selectedCategory;
  SellerDocumentResult? _documentResult;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _otpSent = false;
  bool _otpVerified = false;
  String _verificationId = '';

  bool get _isSeller => _accountType == 'seller';

  static const List<String> _categories = [
    'Grocery & Supermarket',
    'Electronics & Mobiles',
    'Clothing & Fashion',
    'Restaurant & Food',
    'Bakery & Sweets',
    'Salon & Beauty',
    'Hardware & Tools',
    'Pharmacy & Medical',
    'Furniture & Home Decor',
    'Automobile & Spares',
    'Stationery & Books',
    'Jewellery',
    'Real Estate',
    'Services (Repair, Tuition, etc.)',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid phone number!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text.trim()}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() {
            _otpVerified = true;
            _isLoading = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification failed: ${e.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP Sent Successfully!'),
              backgroundColor: Color(0xFF1D9E75),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter OTP!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      // Just verify — don't sign in
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut();

      setState(() {
        _otpVerified = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone Verified! ✅'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSeller && _shopNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your shop name!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSeller && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your business category!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSeller && _documentResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload and verify your business document!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_otpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your phone number first!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
        'accountType': _accountType,
        'points': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };

      if (_isSeller) {
        userData['shopName'] = _shopNameController.text.trim();
        userData['category'] = _selectedCategory ?? '';
        userData['documentType'] = _documentResult!.documentType.name;
        userData['documentNumber'] = _documentResult!.documentNumber;
        userData['documentUrl'] = _documentResult!.documentUrl;
        userData['documentVerified'] = true;
        if (_documentResult!.legalName != null) {
          userData['documentLegalName'] = _documentResult!.legalName!;
        }
      }

      await FirebaseDatabase.instance.ref('users/$uid').set(userData);

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account Created Successfully! 🎉'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserLoginScreen()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error occurred!';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered! Please login.';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6 characters!';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email!';
      } else {
        message = e.message ?? 'Error occurred!';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDeco(String label, IconData icon, bool isDark,
      {String? hint, String? suffixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      suffixText: suffixText,
      filled: true,
      fillColor:
      isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  TextStyle _fieldTextStyle(bool isDark) {
    return TextStyle(
      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                style: _fieldTextStyle(isDark),
                decoration: _fieldDeco(
                    'Full Name', Icons.person_outline_rounded, isDark),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: _fieldTextStyle(isDark),
                decoration:
                _fieldDeco('Email', Icons.mail_outline_rounded, isDark),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: _fieldTextStyle(isDark),
                decoration: _fieldDeco(
                  'Password',
                  Icons.lock_outline_rounded,
                  isDark,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Phone + OTP Section ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      enabled: !_otpVerified,
                      style: _fieldTextStyle(isDark),
                      decoration: _fieldDeco(
                        'Mobile Number',
                        Icons.phone_outlined,
                        isDark,
                      ).copyWith(
                        prefixText: '+91 ',
                        counterText: '',
                        suffixIcon: _otpVerified
                            ? const Icon(Icons.check_circle,
                            color: Color(0xFF1D9E75))
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_otpVerified)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      child: const Text('Send OTP'),
                    ),
                ],
              ),

              if (_otpSent && !_otpVerified) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: _fieldTextStyle(isDark),
                        decoration: _fieldDeco(
                          'Enter OTP',
                          Icons.lock_outline_rounded,
                          isDark,
                        ).copyWith(counterText: ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      child: const Text('Verify'),
                    ),
                  ],
                ),
              ],

              if (_otpVerified)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFF1D9E75).withOpacity(isDark ? .18 : .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFF1D9E75), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Phone Verified!',
                        style: TextStyle(
                          color: Color(0xFF1D9E75),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              Text(
                'ACCOUNT TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textHint,
                ),
              ),
              const SizedBox(height: 10),
              _accountTypeCard(
                isDark: isDark,
                icon: Icons.person_rounded,
                title: 'Normal User',
                subtitle: 'View & enquire about ads',
                value: 'normal',
              ),
              const SizedBox(height: 10),
              _accountTypeCard(
                isDark: isDark,
                icon: Icons.storefront_rounded,
                title: 'Seller',
                subtitle: 'Upload & manage your own ads',
                value: 'seller',
              ),

              // ── Seller-only fields ────────────────────────────────
              if (_isSeller) ...[
                const SizedBox(height: 20),
                Text(
                  'BUSINESS DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _shopNameController,
                  style: _fieldTextStyle(isDark),
                  decoration: _fieldDeco(
                      'Shop / Business Name', Icons.store_outlined, isDark),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  decoration: _fieldDeco(
                      'Business Category', Icons.category_outlined, isDark),
                  hint: Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textHint,
                    ),
                  ),
                  style: _fieldTextStyle(isDark),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, overflow: TextOverflow.ellipsis),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      // Category change may flip food/non-food —
                      // clear any previously verified document.
                      _documentResult = null;
                    });
                  },
                ),

                const SizedBox(height: 20),
                Text(
                  'DOCUMENT VERIFICATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 10),
                SellerDocumentUpload(
                  category: _selectedCategory,
                  isDark: isDark,
                  onVerified: (result) {
                    setState(() => _documentResult = result);
                  },
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserLoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountTypeCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _accountType == value;

    return InkWell(
      onTap: () => setState(() => _accountType = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                isSelected ? AppColors.primary : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _accountType,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _accountType = v!),
            ),
          ],
        ),
      ),
    );
  }
}