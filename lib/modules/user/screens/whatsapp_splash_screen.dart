import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a brief full-screen "Opening WhatsApp..." transition, then launches
/// the WhatsApp chat and closes itself — same idea as Instagram's
/// "Chat on WhatsApp" splash before it hands off to the WhatsApp app.
Future<void> showWhatsAppSplash(
    BuildContext context, {
      required String phone,
      required String message,
      required String sellerName,
    }) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.0),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _WhatsAppSplashScreen(
          phone: phone,
          message: message,
          sellerName: sellerName,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    ),
  );
}

class _WhatsAppSplashScreen extends StatefulWidget {
  final String phone;
  final String message;
  final String sellerName;

  const _WhatsAppSplashScreen({
    required this.phone,
    required this.message,
    required this.sellerName,
  });

  @override
  State<_WhatsAppSplashScreen> createState() => _WhatsAppSplashScreenState();
}

class _WhatsAppSplashScreenState extends State<_WhatsAppSplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _whatsappGreen = Color(0xFF25D366);
  static const Color _whatsappDark = Color(0xFF075E54);

  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  Timer? _launchTimer;
  bool _launching = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );

    _controller.forward();

    _launchTimer = Timer(const Duration(milliseconds: 1100), _launch);
  }

  Future<void> _launch() async {
    if (_launching || !mounted) return;
    _launching = true;

    final digits = widget.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMessage = Uri.encodeComponent(widget.message);
    final url = Uri.parse('https://wa.me/$digits?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // If launch fails we just close the splash silently below —
      // the caller already knows this can happen (WhatsApp not installed etc).
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _whatsappGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: _whatsappGreen,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Opening WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chatting with ${widget.sellerName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}