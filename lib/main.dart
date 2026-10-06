// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'firebase_options.dart';
// import 'modules/user/screens/splash_screen.dart';
// import 'app/theme.dart';
//
// // ── Theme Provider ────────────────────────────────────────────────────
// class ThemeProvider extends ChangeNotifier {
//   ThemeMode _themeMode = ThemeMode.light;
//
//   ThemeMode get themeMode => _themeMode;
//   bool get isDark => _themeMode == ThemeMode.dark;
//
//   void toggleTheme(bool isDark) {
//     _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
//     notifyListeners();
//   }
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => ThemeProvider(),
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final themeMode = context.watch<ThemeProvider>().themeMode;
//     return MaterialApp(
//       title: 'DigitalAds',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: themeMode,
//       home: const SplashScreen(),
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'modules/user/screens/splash_screen.dart';
import 'app/theme.dart';

// ─────────────────────────────────────────────────────────────
// Theme Provider
// ─────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
ThemeMode _themeMode = ThemeMode.light;

ThemeMode get themeMode => _themeMode;

bool get isDark => _themeMode == ThemeMode.dark;

void toggleTheme(bool isDark) {
_themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
notifyListeners();
}
}

// ─────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────
Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

// Initialize Firebase before starting the app.
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);

runApp(
ChangeNotifierProvider(
create: (_) => ThemeProvider(),
child: const MyApp(),
),
);
}

// ─────────────────────────────────────────────────────────────
// My App
// ─────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
final themeProvider = context.watch<ThemeProvider>();

return MaterialApp(
title: 'DigitalAds',

debugShowCheckedModeBanner: false,

// Light theme
theme: AppTheme.lightTheme,

// Dark theme
darkTheme: AppTheme.darkTheme,

// Current theme selected by ThemeProvider
themeMode: themeProvider.themeMode,

// Splash screen handles login/session checking.
home: const SplashScreen(),
);
}
}

