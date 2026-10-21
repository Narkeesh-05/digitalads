import 'package:digitalads/app/theme.dart';
import 'package:digitalads/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Lets a seller edit a product (ad) they already posted.
///
/// Open it with:
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => EditAdScreen(adId: adId)),
/// );
class EditAdScreen extends StatefulWidget {
  final String adId;

  const EditAdScreen({super.key, required this.adId});

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _offerController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  DatabaseReference get _adRef =>
      FirebaseDatabase.instance.ref('ads/${widget.adId}');

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _offerController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    try {
      final snap = await _adRef.get();

      if (!snap.exists || snap.value is! Map) {
        setState(() {
          _loading = false;
          _error = 'This product no longer exists.';
        });
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);

      // Only the seller who posted the ad may edit it.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || data['adminId'] != uid) {
        setState(() {
          _loading = false;
          _error = 'You can only edit your own products.';
        });
        return;
      }

      _titleController.text = (data['title'] ?? '').toString();
      _descriptionController.text = (data['description'] ?? '').toString();
      _offerController.text = (data['offer'] ?? '').toString();
      _locationController.text = (data['location'] ?? '').toString();
      _phoneController.text = (data['phone'] ?? '').toString();

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Load ad error: $e');
      setState(() {
        _loading = false;
        _error = 'Unable to load product. Please try again.';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _adRef.update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'offer': _offerController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully!'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Update ad error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update product.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration({
    required bool isDark,
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary),
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textStyle = TextStyle(
      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                style: textStyle,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  isDark: isDark,
                  label: 'Product Title',
                  icon: Icons.title_rounded,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                style: textStyle,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  isDark: isDark,
                  label: 'Description',
                  icon: Icons.description_outlined,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _offerController,
                style: textStyle,
                decoration: _decoration(
                  isDark: isDark,
                  label: 'Offer (optional)',
                  icon: Icons.local_offer_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                style: textStyle,
                decoration: _decoration(
                  isDark: isDark,
                  label: 'Location',
                  icon: Icons.place_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                style: textStyle,
                keyboardType: TextInputType.phone,
                decoration: _decoration(
                  isDark: isDark,
                  label: 'Phone / WhatsApp Number',
                  icon: Icons.phone_outlined,
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return null;
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}