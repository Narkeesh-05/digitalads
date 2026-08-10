import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class WithdrawalRequestsScreen extends StatefulWidget {
  const WithdrawalRequestsScreen({super.key});

  @override
  State<WithdrawalRequestsScreen> createState() =>
      _WithdrawalRequestsScreenState();
}

class _WithdrawalRequestsScreenState extends State<WithdrawalRequestsScreen> {
  final DatabaseReference _withdrawalsRef = FirebaseDatabase.instance.ref(
    "withdrawals",
  );

  String _filter = "all";
  String? _processingId;

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus(String requestId, String status) async {
    setState(() {
      _processingId = requestId;
    });

    try {
      await _withdrawalsRef.child(requestId).update({"status": status});

      if (!mounted) return;

      _showMessage(
        status == "approved"
            ? "Withdrawal request approved"
            : "Withdrawal request rejected",
        status == "approved" ? Colors.green : Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage("Unable to update request", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _processingId = null;
        });
      }
    }
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  Future<void> _confirmAction(
    Map<String, dynamic> request,
    String status,
  ) async {
    final isApprove = status == "approved";

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (isApprove ? Colors.green : Colors.red).withOpacity(
                    .1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApprove
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: isApprove ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isApprove ? "Approve Withdrawal?" : "Reject Withdrawal?",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isApprove
                ? "Are you sure you want to approve the withdrawal of ₹${request["amount"] ?? 0}?"
                : "Are you sure you want to reject this withdrawal request?",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(isApprove ? "Approve" : "Reject"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _updateStatus(request["id"].toString(), status);
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
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Icons.check_circle_outline;

      case "rejected":
        return Icons.cancel_outlined;

      default:
        return Icons.pending_outlined;
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return "-";
    }

    try {
      final date = DateTime.parse(value.toString());

      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];

      return "${date.day} "
          "${months[date.month - 1]} "
          "${date.year}";
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101114)
          : const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Withdrawal Requests",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: StreamBuilder<DatabaseEvent>(
        stream: _withdrawalsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _errorState(isDark, snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _emptyState(isDark);
          }

          final rawData = snapshot.data!.snapshot.value;

          if (rawData is! Map) {
            return _emptyState(isDark);
          }

          final requestsMap = Map<dynamic, dynamic>.from(rawData);

          final allRequests = requestsMap.entries.map((entry) {
            final data = Map<String, dynamic>.from(entry.value as Map);

            return {"id": entry.key.toString(), ...data};
          }).toList();

          allRequests.sort((a, b) {
            return (b["createdAt"] ?? "").toString().compareTo(
              (a["createdAt"] ?? "").toString(),
            );
          });

          final filteredRequests = _filterRequests(allRequests);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await _withdrawalsRef.get();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              children: [
                _summaryCard(isDark, allRequests),

                const SizedBox(height: 18),

                _filterBar(isDark),

                const SizedBox(height: 16),

                if (filteredRequests.isEmpty)
                  _emptyFilteredState(isDark)
                else
                  ...filteredRequests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _requestCard(isDark, request),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> _filterRequests(
    List<Map<String, dynamic>> requests,
  ) {
    if (_filter == "all") {
      return requests;
    }

    return requests.where((request) {
      return (request["status"] ?? "pending").toString().toLowerCase() ==
          _filter;
    }).toList();
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _filterBar(bool isDark) {
    final filters = [
      ("all", "All"),
      ("pending", "Pending"),
      ("approved", "Approved"),
      ("rejected", "Rejected"),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final selected = _filter == item.$1;

          return GestureDetector(
            onTap: () {
              setState(() {
                _filter = item.$1;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : isDark
                    ? const Color(0xFF1B1C20)
                    : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : isDark
                      ? Colors.white10
                      : Colors.black12,
                ),
              ),
              child: Text(
                item.$2,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : isDark
                      ? Colors.white70
                      : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard(bool isDark, List<Map<String, dynamic>> requests) {
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    double totalAmount = 0;

    for (final request in requests) {
      final status = (request["status"] ?? "pending").toString().toLowerCase();

      if (status == "pending") {
        pending++;
      } else if (status == "approved") {
        approved++;
      } else if (status == "rejected") {
        rejected++;
      }

      totalAmount += double.tryParse(request["amount"]?.toString() ?? "0") ?? 0;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF756FD0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.22),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 9),
              Text(
                "Withdrawal Overview",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _summaryItem("Total", requests.length.toString()),
              _summaryItem("Pending", pending.toString()),
              _summaryItem("Approved", approved.toString()),
              _summaryItem("Rejected", rejected.toString()),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Total Requested",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  "₹${totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _requestCard(bool isDark, Map<String, dynamic> request) {
    final status = (request["status"] ?? "pending").toString().toLowerCase();

    final statusColor = _statusColor(status);

    final isProcessing = _processingId == request["id"].toString();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191A1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(.06) : Colors.transparent,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(.045),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            // --------------------------------------------------
            // USER HEADER
            // --------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request["accountName"]?.toString() ?? "-",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "A/C : ${request["accountNumber"] ?? "-"}",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        "IFSC : ${request["ifscCode"] ?? "-"}",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _statusChip(status, statusColor),
              ],
            ),

            const SizedBox(height: 17),

            Divider(
              height: 1,
              color: isDark ? Colors.white10 : Colors.black.withOpacity(.07),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // POINTS + AMOUNT
            // --------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _moneyInfo(
                    isDark,
                    icon: Icons.stars_outlined,
                    label: "Points",
                    value: "${request["points"] ?? 0}",
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _moneyInfo(
                    isDark,
                    icon: Icons.currency_rupee,
                    label: "Amount",
                    value: "₹${request["amount"] ?? 0}",
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // DATE
            // --------------------------------------------------
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 15,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(request["createdAt"]),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            // --------------------------------------------------
            // ACTIONS
            // --------------------------------------------------
            if (status == "pending") ...[
              const SizedBox(height: 17),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _confirmAction(request, "rejected"),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text("Reject"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _confirmAction(request, "approved"),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(isProcessing ? "Updating..." : "Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MONEY INFO
  // ============================================================

  Widget _moneyInfo(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "No Withdrawal Requests",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              "Withdrawal requests from users will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER EMPTY
  // ============================================================

  Widget _emptyFilteredState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 45,
            color: isDark ? Colors.white24 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            "No $_filter requests",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorState(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: Colors.red,
            ),

            const SizedBox(height: 14),

            Text(
              "Unable to load withdrawals",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
