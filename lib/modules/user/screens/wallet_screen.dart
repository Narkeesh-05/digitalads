import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _accountNumberController.dispose();
    _ifscController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF4F5F9),
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

  Future<void> _requestWithdrawal(int points) async {
    if (points < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 100 points required to withdraw!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _nameController.clear();
    _accountNumberController.clear();
    _ifscController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Bank Transfer',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration:
                _fieldDeco('Account Holder Name', Icons.person_outline),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: _fieldDeco(
                    'Account Number', Icons.account_balance_outlined),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                decoration: _fieldDeco('IFSC Code', Icons.code_rounded),
              ),
            ],
          ),
        ),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty ||
                  _accountNumberController.text.trim().isEmpty ||
                  _ifscController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              await FirebaseDatabase.instance
                  .ref('withdrawals')
                  .push()
                  .set({
                'userId': _userId,
                'points': points,
                'amount': points / 10,
                'accountName': _nameController.text.trim(),
                'accountNumber': _accountNumberController.text.trim(),
                'ifscCode': _ifscController.text.trim().toUpperCase(),
                'status': 'pending',
                'createdAt': DateTime.now().toIso8601String(),
              });

              await FirebaseDatabase.instance
                  .ref('users/$_userId/points')
                  .set(0);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Withdrawal Request Submitted!'),
                    backgroundColor: Color(0xFF1D9E75),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users/$_userId').onValue,
        builder: (context, snapshot) {
          int points = 0;
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map);
            points = (data['points'] ?? 0) as int;
          }

          double amount = points / 10;
          bool canWithdraw = points >= 100;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 16,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 560 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPointsCard(points, amount),
                        const SizedBox(height: 20),
                        _buildStatusBanner(canWithdraw, points),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: canWithdraw
                                ? () => _requestWithdrawal(points)
                                : null,
                            icon: const Icon(Icons.account_balance_rounded,
                                size: 20),
                            label: const Text(
                              'Withdraw to Bank',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPointsCard(int points, double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF7A72D6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                size: 34, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            '$points Points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white.withOpacity(.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '10 Points = ₹1',
              style: TextStyle(
                color: Colors.white.withOpacity(.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool canWithdraw, int points) {
    final color = canWithdraw ? const Color(0xFF1D9E75) : Colors.orange;
    final bgColor =
    canWithdraw ? const Color(0xFFE3F6EF) : const Color(0xFFFFF3CD);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              canWithdraw
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              canWithdraw
                  ? 'You can withdraw now!'
                  : 'Need ${100 - points} more points to withdraw!',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}