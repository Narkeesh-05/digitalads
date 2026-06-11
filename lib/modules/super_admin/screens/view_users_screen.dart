import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ViewUsersScreen extends StatelessWidget {
  const ViewUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
          (snapshot.data!.snapshot.value ?? {}) as Map<dynamic, dynamic>;

          final users = data.entries.where((e) {
            final user = Map<String, dynamic>.from(e.value);
            return user['accountType'] == 'normal';
          }).toList();

          if (users.isEmpty) {
            return const Center(
              child: Text('No Users Found'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final uid = users[index].key;
              final user =
              Map<String, dynamic>.from(users[index].value);

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(user['name'] ?? ''),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.block,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      await FirebaseDatabase.instance
                          .ref('users/$uid/status')
                          .set('inactive');

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User Deactivated'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}