import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../main.dart';
import 'user_details_screen.dart';

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  State<ViewUsersScreen> createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen> {
  String _searchQuery = '';

  Future<void> _updateStatus(
      BuildContext context, String uid, String status) async {
    await FirebaseDatabase.instance.ref('users/$uid/status').set(status);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'active' ? 'User Activated' : 'User Deactivated',
          ),
          backgroundColor:
          status == 'active' ? const Color(0xFF1D9E75) : Colors.orange,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User?'),
        content: Text(
          'This will permanently remove "$name" from the database. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseDatabase.instance.ref('users/$uid').remove();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User Deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : const Color(0xFFF4F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'All Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textHint,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textHint,
                ),
                filled: true,
                fillColor:
                isDark ? AppColors.darkSurfaceVariant : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('users').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final raw = (snapshot.data!.snapshot.value ?? {})
                as Map<dynamic, dynamic>;

                var users = raw.entries.where((e) {
                  final user = Map<String, dynamic>.from(e.value);
                  return user['accountType'] == 'normal';
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  users = users.where((e) {
                    final user = Map<String, dynamic>.from(e.value);
                    final name =
                    (user['name'] ?? '').toString().toLowerCase();
                    final email =
                    (user['email'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 56,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No Users Found',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;

                    if (!isWide) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: users.length,
                        itemBuilder: (context, index) => _UserCard(
                          uid: users[index].key,
                          user: Map<String, dynamic>.from(
                              users[index].value),
                          isDark: isDark,
                          onActivate: (uid) =>
                              _updateStatus(context, uid, 'active'),
                          onDeactivate: (uid) =>
                              _updateStatus(context, uid, 'inactive'),
                          onDelete: _confirmDelete,
                        ),
                      );
                    }

                    final crossAxisCount =
                    constraints.maxWidth > 1100 ? 3 : 2;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 118,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) => _UserCard(
                        uid: users[index].key,
                        user: Map<String, dynamic>.from(users[index].value),
                        isDark: isDark,
                        onActivate: (uid) =>
                            _updateStatus(context, uid, 'active'),
                        onDeactivate: (uid) =>
                            _updateStatus(context, uid, 'inactive'),
                        onDelete: _confirmDelete,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String? uid;
  final Map<String, dynamic> user;
  final bool isDark;
  final void Function(String uid) onActivate;
  final void Function(String uid) onDeactivate;
  final void Function(BuildContext context, String uid, String name)
  onDelete;

  const _UserCard({
    required this.uid,
    required this.user,
    required this.isDark,
    required this.onActivate,
    required this.onDeactivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = (user['status'] ?? 'active').toString();
    final isActive = status == 'active';
    final name = (user['name'] ?? 'Unnamed').toString();
    final email = (user['email'] ?? '').toString();
    final photoUrl =
    (user['photoUrl'] ?? user['profileImage'] ?? '').toString();

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: uid == null
            ? null
            : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailsScreen(userId: uid!),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(.1),
                backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isActive
                            ? const Color(0xFF1D9E75)
                            : Colors.orange)
                            .withOpacity(.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF1D9E75)
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : Colors.grey.shade600,
                ),
                onSelected: (value) {
                  if (uid == null) return;
                  if (value == 'activate') onActivate(uid!);
                  if (value == 'deactivate') onDeactivate(uid!);
                  if (value == 'delete') onDelete(context, uid!, name);
                  if (value == 'view') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailsScreen(userId: uid!),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Details'),
                  ),
                  if (!isActive)
                    const PopupMenuItem(
                      value: 'activate',
                      child: Text('Activate'),
                    ),
                  if (isActive)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Text('Deactivate'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}