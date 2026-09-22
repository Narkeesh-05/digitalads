import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../main.dart';
import '../../user/screens/seller_document_upload.dart';

class AddSellerScreen extends StatefulWidget {
  const AddSellerScreen({super.key});

  @override
  State<AddSellerScreen> createState() => _AddSellerScreenState();
}

class _AddSellerScreenState extends State<AddSellerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Same category list used on the seller self-registration screen, so
  // "food category -> FSSAI" detection stays consistent everywhere.
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

  String? _selectedCategory;
  SellerDocumentResult? _documentResult;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveSeller() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a business category!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_documentResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload and verify the business document first!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    FirebaseApp? tempApp;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('Admin session expired. Please login again.');
      }

      final businessAdminUid = currentUser.uid;

      // Create temporary Firebase app so the current admin
      // does not get signed out when creating the seller.
      tempApp = await Firebase.initializeApp(
        name: 'TempSellerCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // Create seller Firebase Auth account.
      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final sellerUid = userCredential.user!.uid;

      final now = DateTime.now().toIso8601String();

      final documentTypeLabel = _documentResult!.documentType.name; // fssai / gst / msme

      // Save common user profile.
      await FirebaseDatabase.instance.ref('users/$sellerUid').set({
        'name': _ownerNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
        'accountType': 'seller',
        'points': 0,
        'status': 'active',
        'documentVerified': true,
        'createdAt': now,
      });

      // Save seller/business information, including verified document details.
      await FirebaseDatabase.instance.ref('sellers/$sellerUid').set({
        'sellerId': sellerUid,
        'shopName': _shopNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'category': _selectedCategory,
        'documentType': documentTypeLabel,
        'documentNumber': _documentResult!.documentNumber,
        'documentUrl': _documentResult!.documentUrl,
        'documentVerified': true,
        if (_documentResult!.legalName != null)
          'documentLegalName': _documentResult!.legalName,
        'createdBy': businessAdminUid,
        'status': 'active',
        'createdAt': now,
      });

      await tempAuth.signOut();
      await tempApp.delete();
      tempApp = null;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller account created successfully!'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }

      String message = 'Error occurred!';

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
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = e.message ?? 'Error occurred!';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add seller: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF252936) : const Color(0xFFF4F5F9),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(.08) : Colors.transparent,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 11.5, color: AppColors.error),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.grey.shade300 : AppColors.textSecondary,
        letterSpacing: .2,
      ),
    );
  }

  Widget _infoBox(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withOpacity(.12)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withOpacity(.25)
              : AppColors.primary.withOpacity(.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withOpacity(.18)
                  : Colors.white.withOpacity(.65),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This creates a login account for the seller. '
                  'They can sign in to the app using this email and password.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: isDark ? Colors.grey.shade300 : AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E212B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(.06) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .15 : .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    final backgroundColor =
    isDark ? AppColors.darkBackground : const Color(0xFFF4F5F9);

    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Add Seller / Merchant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _infoBox(isDark),

                        const SizedBox(height: 24),

                        _sectionTitle('SHOP DETAILS', isDark),
                        const SizedBox(height: 10),

                        _formCard(
                          isDark: isDark,
                          children: [
                            TextFormField(
                              controller: _shopNameController,
                              style: TextStyle(
                                  color: primaryTextColor, fontSize: 14),
                              decoration: _fieldDecoration(
                                'Shop name',
                                Icons.storefront_outlined,
                                isDark,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter shop name'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              dropdownColor:
                              isDark ? AppColors.darkSurface : Colors.white,
                              decoration: _fieldDecoration(
                                'Business Category',
                                Icons.category_outlined,
                                isDark,
                              ),
                              hint: Text(
                                'Select Category',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : AppColors.textHint,
                                ),
                              ),
                              style: TextStyle(
                                  color: primaryTextColor, fontSize: 14),
                              items: _categories
                                  .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat,
                                    overflow: TextOverflow.ellipsis),
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
                              validator: (v) =>
                              v == null ? 'Select a category' : null,
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _addressController,
                              style: TextStyle(
                                  color: primaryTextColor, fontSize: 14),
                              maxLines: 2,
                              decoration: _fieldDecoration(
                                'Shop address',
                                Icons.location_on_outlined,
                                isDark,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter address'
                                  : null,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _sectionTitle('OWNER / LOGIN DETAILS', isDark),
                        const SizedBox(height: 10),

                        _formCard(
                          isDark: isDark,
                          children: [
                            TextFormField(
                              controller: _ownerNameController,
                              style: TextStyle(
                                  color: primaryTextColor, fontSize: 14),
                              decoration: _fieldDecoration(
                                'Owner name',
                                Icons.person_outline_rounded,
                                isDark,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter owner name'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: TextStyle(
                                  color: primaryTextColor, fontSize: 14),
                              decoration: _fieldDecoration(
                                'Phone number',
                                Icons.phone_outlined,
                                isDark,
                              ).copyWith(
                                prefixText: '+91 ',
                                counterText: '',
                                prefixStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter phone number';
                                }
                                final phone = v.trim();
                                if (phone.length != 10) {
                                  return 'Enter a valid 10-digit number';
                                }
                                if (!RegExp(r'^[6-9][0-9]{9}$')
                                    .hasMatch(phone)) {
                                  return 'Enter a valid Indian phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                  color: primaryTextColor, fontSize: 14),
                              decoration: _fieldDecoration(
                                'Email (used for seller login)',
                                Icons.mail_outline_rounded,
                                isDark,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter email';
                                }
                                final emailRegex =
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                  color: primaryTextColor, fontSize: 14),
                              decoration: _fieldDecoration(
                                'Password (used for seller login)',
                                Icons.lock_outline_rounded,
                                isDark,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter password';
                                }
                                if (v.length < 6) {
                                  return 'Minimum 6 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _sectionTitle('DOCUMENT VERIFICATION', isDark),
                        const SizedBox(height: 10),

                        SellerDocumentUpload(
                          category: _selectedCategory,
                          isDark: isDark,
                          onVerified: (result) {
                            setState(() => _documentResult = result);
                          },
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSeller,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              AppColors.primary.withOpacity(.5),
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
                                : const Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_alt_1_rounded,
                                    size: 19),
                                SizedBox(width: 8),
                                Text(
                                  'Create Seller Account',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}