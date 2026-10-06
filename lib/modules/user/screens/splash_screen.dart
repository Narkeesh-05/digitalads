// import 'package:digitalads/modules/user/screens/welcome_screen.dart';
// import 'package:flutter/material.dart';
//
// class SplashScreen extends StatefulWidget {
//   const
//   SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _navigate();
//   }
//
//
//   Future<void> _navigate() async {
//     await Future.delayed(const Duration(seconds: 3));
//     if (mounted) {
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const WelcomeScreen(),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: Colors.blue,
//       body: Center(
//         child: Image(image: AssetImage('assets/images/img.png')),
//       ),
//     );
//   }
// }
//
// import 'package:digitalads/modules/user/screens/welcome_screen.dart';
// import 'package:digitalads/modules/user/screens/user_home_screen.dart';
// import 'package:digitalads/modules/admin/screens/bloc/admin_home_screen.dart';
// import 'package:digitalads/modules/super_admin/screens/super_admin_dashboard.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _navigate();
//   }
//
//   Future<void> _navigate() async {
//     await Future.delayed(const Duration(seconds: 3));
//
//     if (!mounted) return;
//
//     final user = FirebaseAuth.instance.currentUser;
//
//     // No user logged in → WelcomeScreen
//     if (user == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const WelcomeScreen()),
//       );
//       return;
//     }
//
//     final uid = user.uid;
//
//     // Check if Business Admin
//     final adminSnapshot =
//     await FirebaseDatabase.instance.ref('admins/$uid').get();
//
//     if (adminSnapshot.exists) {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
//         );
//       }
//       return;
//     }
//
//     // Check users node
//     final userSnapshot =
//     await FirebaseDatabase.instance.ref('users/$uid').get();
//
//     if (userSnapshot.exists) {
//       final userData =
//       Map<String, dynamic>.from(userSnapshot.value as Map);
//
//       final status = userData['status'] ?? 'active';
//
//       // Inactive user → WelcomeScreen
//       if (status == 'inactive') {
//         await FirebaseAuth.instance.signOut();
//         if (mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const WelcomeScreen()),
//           );
//         }
//         return;
//       }
//
//       final role = userData['role'] ?? 'user';
//
//       if (mounted) {
//         if (role == 'super_admin') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (_) => const SuperAdminDashboard()),
//           );
//         } else {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const UserHomeScreen()),
//           );
//         }
//       }
//       return;
//     }
//
//     // User not found → WelcomeScreen
//     await FirebaseAuth.instance.signOut();
//     if (mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const WelcomeScreen()),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Image(image: AssetImage('assets/images/img.png')),
//       ),
//     );
//   }
// }

import 'package:digitalads/modules/user/screens/welcome_screen.dart';
import 'package:digitalads/modules/user/screens/user_home_screen.dart';
import 'package:digitalads/modules/admin/screens/bloc/admin_home_screen.dart';
import 'package:digitalads/modules/super_admin/screens/super_admin_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
const SplashScreen({super.key});

@override
State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
@override
void initState() {
super.initState();
_checkLoginStatus();
}

Future<void> _checkLoginStatus() async {
// Small delay so Firebase can restore the previous login session.
await Future.delayed(const Duration(milliseconds: 800));

if (!mounted) return;

try {
final auth = FirebaseAuth.instance;
final database = FirebaseDatabase.instance;

// Firebase automatically restores the previously logged-in user.
final user = auth.currentUser;

// ------------------------------------------------------------
// 1. USER IS NOT LOGGED IN
// ------------------------------------------------------------
if (user == null) {
_goToWelcome();
return;
}

final uid = user.uid;

debugPrint('Splash: Logged-in UID = $uid');

// ------------------------------------------------------------
// 2. CHECK BUSINESS ADMIN
// ------------------------------------------------------------
final adminSnapshot = await database.ref('admins/$uid').get();

if (adminSnapshot.exists) {
debugPrint('Splash: Business Admin found');

// Check admin status also.
final adminData =
Map<String, dynamic>.from(adminSnapshot.value as Map);

final status = adminData['status'] ?? 'active';

if (status.toString().toLowerCase() == 'inactive') {
debugPrint('Splash: Business Admin is inactive');

await auth.signOut();

if (mounted) {
_goToWelcome();
}
return;
}

if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const AdminHomeScreen(),
),
);
}

return;
}

// ------------------------------------------------------------
// 3. CHECK USERS NODE
// ------------------------------------------------------------
final userSnapshot = await database.ref('users/$uid').get();

if (userSnapshot.exists) {
final rawData = userSnapshot.value;

if (rawData is! Map) {
debugPrint('Splash: Invalid user data');

await auth.signOut();

if (mounted) {
_goToWelcome();
}
return;
}

final userData = Map<String, dynamic>.from(rawData);

final status =
(userData['status'] ?? 'active').toString().toLowerCase();

final role =
(userData['role'] ?? 'user').toString().toLowerCase();

debugPrint('Splash: Role = $role');
debugPrint('Splash: Status = $status');

// ----------------------------------------------------------
// INACTIVE ACCOUNT
// ----------------------------------------------------------
if (status == 'inactive') {
debugPrint('Splash: User account is inactive');

await auth.signOut();

if (mounted) {
_goToWelcome();
}

return;
}

// ----------------------------------------------------------
// SUPER ADMIN
// ----------------------------------------------------------
if (role == 'super_admin') {
debugPrint('Splash: Opening Super Admin Dashboard');

if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const SuperAdminDashboard(),
),
);
}

return;
}

// ----------------------------------------------------------
// NORMAL USER / SELLER
// ----------------------------------------------------------
debugPrint('Splash: Opening User Home');

if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const UserHomeScreen(),
),
);
}

return;
}

// ------------------------------------------------------------
// 4. AUTH USER EXISTS BUT DATABASE RECORD DOES NOT EXIST
// ------------------------------------------------------------
debugPrint('Splash: User exists in Firebase Auth but not database');

await auth.signOut();

if (mounted) {
_goToWelcome();
}
} catch (e) {
debugPrint('Splash Error: $e');

// If something goes wrong while checking the database,
// don't automatically sign the user out.
//
// This is important for "Stay Login".
// A temporary Firebase/network error should NOT log the
// user out.

if (mounted) {
_goToWelcome();
}
}
}

void _goToWelcome() {
if (!mounted) return;

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const WelcomeScreen(),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Center(
child: Image.asset(
'assets/images/img.png',
),
),
);
}
}

