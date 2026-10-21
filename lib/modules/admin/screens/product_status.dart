import 'package:flutter/material.dart';

/// Product status stored at ads/{adId}/status.
/// Ads without a status field (older ads) count as available.
///
/// Put this file at lib/core/product_status.dart
class ProductStatus {
  ProductStatus._();

  static const String available = 'available';
  static const String sold = 'sold';

  static bool isSold(Map<dynamic, dynamic> ad) =>
      (ad['status'] ?? available).toString().toLowerCase() == sold;
}

/// Small "Available" / "Sold" badge.
class ProductStatusChip extends StatelessWidget {
  final bool isSold;

  const ProductStatusChip({super.key, required this.isSold});

  @override
  Widget build(BuildContext context) {
    final color = isSold ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isSold ? 'Sold' : 'Available',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}