import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';

class SellerContactSection extends StatefulWidget {
  final String sellerId; // == ad['adminId']

  const SellerContactSection({super.key, required this.sellerId});

  @override
  State<SellerContactSection> createState() => _SellerContactSectionState();
}

class _SellerContactSectionState extends State<SellerContactSection> {
  bool _loading = true;
  String? _phone;
  String? _sellerName;

  static const _lookupNodes = ['admins', 'sellers', 'users'];

  @override
  void initState() {
    super.initState();
    _loadSellerContact();
  }

  Future<void> _loadSellerContact() async {
    for (final node in _lookupNodes) {
      try {
        final snapshot = await FirebaseDatabase.instance.ref('$node/${widget.sellerId}').get();
        if (!snapshot.exists) continue;

        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final phone = data['phone'] ?? data['phoneNumber'] ?? data['mobile'];

        if (phone != null && phone.toString().trim().isNotEmpty) {
          if (mounted) {
            setState(() {
              _phone = phone.toString();
              _sellerName = (data['name'] ?? data['businessName'])?.toString();
              _loading = false;
            });
          }
          return;
        }
      } catch (_) {
        // Try the next node — a permission error or missing node on one
        // shouldn't stop the search.
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  /// Digits and a leading '+' only — what tel:/wa.me links need.
  String get _normalizedPhone => (_phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _normalizedPhone);
    if (!await launchUrl(uri)) _showUnavailable();
  }

  Future<void> _whatsapp() async {
    final digits = _normalizedPhone.replaceFirst('+', ''); // wa.me wants no '+'
    final uri = Uri.parse('https://wa.me/$digits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) _showUnavailable();
  }

  void _showUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open that app — is it installed?')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    if (_phone == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Seller contact not available', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sellerName ?? 'Seller',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(_phone!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _call,
            icon: const Icon(Icons.call_rounded, size: 19),
            style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: _whatsapp,
            icon: const Icon(Icons.chat_rounded, size: 19),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}