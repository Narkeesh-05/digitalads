import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/widgets/confirm_dialog.dart';
import 'admin_ads_screen.dart';

class ViewAdminsScreen extends StatefulWidget {
  const ViewAdminsScreen({super.key});

  @override
  State<ViewAdminsScreen> createState() => _ViewAdminsScreenState();
}

class _ViewAdminsScreenState extends State<ViewAdminsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('admins');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Business Admins',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_mall_directory_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Business Admins Yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> adminsMap =
          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          List<Map<String, dynamic>> adminsList = adminsMap.entries.map((e) {
            return {
              'uid': e.key,
              ...Map<String, dynamic>.from(e.value),
            };
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminsList.length,
            itemBuilder: (context, index) {
              final admin = adminsList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          child: const Icon(Icons.store, color: Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                admin['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                admin['businessName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                admin['email'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminAdsScreen(
                                      adminId: admin['uid'],
                                      adminName: admin['name'] ?? '',
                                    ),
                                  ),
                                );
                              },
                            ),
                            // IconButton(
                            //   icon: Icon(
                            //     admin['status'] == 'inactive'
                            //         ? Icons.check_circle
                            //         : Icons.block,
                            //     color: admin['status'] == 'inactive'
                            //         ? Colors.green
                            //         : Colors.red,
                            //   ),
                            // onPressed: () async {
                            //     final isInactive = admin['status'] == 'inactive';
                            //     bool confirm = await showConfirmDialog(
                            //       context,
                            //       title: isInactive
                            //           ? 'Activate Admin'
                            //           : 'Deactivate Admin',
                            //       message: isInactive
                            //           ? 'Are you sure you want to activate this business admin?'
                            //           : 'Are you sure you want to deactivate this business admin?',
                            //     );
                            //     if (!confirm) return;
                            //     final newStatus =
                            //     isInactive ? 'active' : 'inactive';
                            //     await FirebaseDatabase.instance
                            //         .ref('admins/${admin['uid']}/status')
                            //         .set(newStatus);
                            //     if (mounted) {
                            //       ScaffoldMessenger.of(context).showSnackBar(
                            //         SnackBar(
                            //           content: Text(
                            //             isInactive
                            //                 ? 'Business Admin Activated'
                            //                 : 'Business Admin Deactivated',
                            //           ),
                            //           backgroundColor:
                            //           isInactive ? Colors.green : Colors.orange,
                            //         ),
                            //       );
                            //     }
                            //   },
                            // ),

                            PopupMenuButton<String>(
                              onSelected: (value) async {

                                if (value == 'activate') {
                                  bool confirm = await showConfirmDialog(
                                    context,
                                    title: 'Activate Admin',
                                    message:
                                    'Are you sure you want to activate this business admin?',
                                  );

                                  if (!confirm) return;

                                  await FirebaseDatabase.instance
                                      .ref('admins/${admin['uid']}/status')
                                      .set('active');

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Business Admin Activated'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }

                                if (value == 'deactivate') {
                                  bool confirm = await showConfirmDialog(
                                    context,
                                    title: 'Deactivate Admin',
                                    message:
                                    'Are you sure you want to deactivate this business admin?',
                                  );

                                  if (!confirm) return;

                                  await FirebaseDatabase.instance
                                      .ref('admins/${admin['uid']}/status')
                                      .set('inactive');

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Business Admin Deactivated'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              },

                              itemBuilder: (context) {
                                final isInactive =
                                    (admin['status'] ?? 'active') == 'inactive';

                                return [
                                  if (isInactive)
                                    const PopupMenuItem(
                                      value: 'activate',
                                      child: Text('Activate'),
                                    ),

                                  if (!isInactive)
                                    const PopupMenuItem(
                                      value: 'deactivate',
                                      child: Text('Deactivate'),
                                    ),
                                ];
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${admin['status'] ?? 'active'}',
                      style: TextStyle(
                        color: admin['status'] == 'inactive'
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}