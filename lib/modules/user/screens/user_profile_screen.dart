import 'package:digitalads/app/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final snapshot =
    await FirebaseDatabase.instance.ref('users/$uid').get();

    if (snapshot.exists) {
      userData =
      Map<String, dynamic>.from(snapshot.value as Map);
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget buildTile(
      IconData icon,
      String title,
      String value,
      ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
        ),
        title: Text(title),
        subtitle: Text(
          value.isEmpty ? "-" : value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = userData?['profileImage'] ?? "";
    final name = userData?['name'] ?? "";
    final email = userData?['email'] ?? "";
    final phone = userData?['phone'] ?? "";
    final age = userData?['age'] ?? "";
    final address = userData?['address'] ?? "";
    final pincode = userData?['pincode'] ?? "";
    final accountType = userData?['accountType'] ?? "";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme:
        const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            CircleAvatar(
              radius: 60,
              backgroundColor:
              Colors.grey.shade300,
              backgroundImage: profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage.isEmpty
                  ? const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              )
                  : null,
            ),

            const SizedBox(height: 20),

            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              accountType.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            buildTile(
              Icons.email,
              "Email",
              email,
            ),

            buildTile(
              Icons.phone,
              "Phone",
              phone,
            ),

            buildTile(
              Icons.cake,
              "Age",
              age.toString(),
            ),

            buildTile(
              Icons.location_on,
              "Address",
              address,
            ),

            buildTile(
              Icons.pin_drop,
              "Pincode",
              pincode.toString(),
            ),

            buildTile(
              Icons.person_outline,
              "Account Type",
              accountType,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.primary,
                ),
                onPressed: () {

                  // Navigate to Edit Profile Screen

                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                label: const Text(
                  "Edit Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}