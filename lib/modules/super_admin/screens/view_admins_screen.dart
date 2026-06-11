import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
                        // IconButton(
                        //   icon: const Icon(Icons.delete, color: Colors.red),
                        //   onPressed: () async {
                        //     await FirebaseDatabase.instance
                        //         .ref('admins/${admin['uid']}')
                        //         .remove();
                        //     if (context.mounted) {
                        //       ScaffoldMessenger.of(context).showSnackBar(
                        //         const SnackBar(
                        //           content: Text('Admin Deleted!'),
                        //           backgroundColor: Colors.red,
                        //         ),
                        //       );
                        //     }
                        //   },
                        // ),
                        IconButton(
                          icon: Icon(
                            admin['status'] == 'inactive'
                                ? Icons.check_circle
                                : Icons.block,
                            color: admin['status'] == 'inactive'
                                ? Colors.green
                                : Colors.red,
                          ),
                          onPressed: () async {
                            final newStatus =
                            admin['status'] == 'inactive'
                                ? 'active'
                                : 'inactive';

                            await FirebaseDatabase.instance
                                .ref('admins/${admin['uid']}/status')
                                .set(newStatus);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    newStatus == 'inactive'
                                        ? 'Admin Deactivated'
                                        : 'Admin Activated',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
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