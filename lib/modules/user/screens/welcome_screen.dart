import 'package:digitalads/modules/user/screens/user_login_screen.dart';
import 'package:digitalads/modules/user/screens/user_register_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../app/theme.dart';

/// First screen a new visitor sees, before login. Resolves the device's
/// location itself (same permission flow as the rest of the app's
/// geolocation-based ad matching) so the location pill is real, not a
/// placeholder passed in from outside.
class WelcomeScreen extends StatefulWidget {
  /// Optional override — pass this if a parent screen/bloc has already
  /// resolved the location, to skip this widget's own fetch.
  final String? locationLabel;

  final VoidCallback? onSearchTap;
  final VoidCallback? onPostAdTap;
  final ValueChanged<String>? onCategoryTap;

  /// Defaults to pushing RegisterScreen directly if not overridden.
  final VoidCallback? onGetStarted;
  final VoidCallback? onLogin;

  const WelcomeScreen({
    super.key,
    this.locationLabel,
    this.onSearchTap,
    this.onPostAdTap,
    this.onCategoryTap,
    this.onGetStarted,
    this.onLogin,
  });

  // A warm accent alongside the brand purple — the purple alone reads flat
  // for a "rewards" moment, so CTAs and the wallet/quiz highlight borrow
  // this coral instead of leaning on primary for everything.
  static const Color accent = Color(0xFFFF7A59);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late String _locationLabel = widget.locationLabel ?? 'Detecting location...';

  @override
  void initState() {
    super.initState();
    if (widget.locationLabel == null) {
      _resolveLocation();
    }
  }

  Future<void> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[WELCOME] location service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationLabel = 'Enable location');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[WELCOME] initial permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[WELCOME] permission after request: $permission');
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLabel = 'Set location');
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      debugPrint('[WELCOME] position: ${position.latitude}, ${position.longitude}');

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      debugPrint('[WELCOME] placemarks: $placemarks');

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = (place.locality != null && place.locality!.isNotEmpty)
            ? place.locality!
            : (place.subAdministrativeArea ?? place.administrativeArea ?? 'Nearby');
        setState(() => _locationLabel = city);
      } else {
        debugPrint('[WELCOME] placemarkFromCoordinates returned an empty list');
        setState(() => _locationLabel = 'Set location');
      }
    } catch (e, st) {
      debugPrint('[WELCOME] location resolution THREW: $e');
      debugPrint('$st');
      if (mounted) setState(() => _locationLabel = 'Set location');
    }
  }

  Future<void> _onLocationPillTap() async {
    if (_locationLabel == 'Enable location') {
      await Geolocator.openLocationSettings();
      return;
    }
    if (_locationLabel == 'Set location') {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
    }
    _resolveLocation();
  }

  void _goToLogin(BuildContext context) {
    if (widget.onLogin != null) {
      widget.onLogin!();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserLoginScreen()));
  }

  void _goToRegister(BuildContext context) {
    if (widget.onGetStarted != null) {
      widget.onGetStarted!();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserRegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _Hero(
            locationLabel: _locationLabel,
            onChangeLocation: _onLocationPillTap,
          ),
          // Takes whatever space is left between the hero and the fixed
          // bottom buttons. No scrolling here: on a short screen the
          // FittedBox scales the whole block down uniformly to fit,
          // instead of allowing it to scroll.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Transform.translate(
                      // Pull the white content up so it overlaps the
                      // curved hero, the way the search bar sits on the
                      // fold in the brief.
                      offset: const Offset(0, -24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SearchBar(onTap: widget.onSearchTap),
                            const SizedBox(height: 18),
                            _CategoryStrip(onTap: widget.onCategoryTap),
                            const SizedBox(height: 20),
                            _PostAdBanner(onTap: widget.onPostAdTap),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Fixed — always visible, never scrolls out of reach.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PrimaryButton(label: 'Get started', onTap: () => _goToRegister(context)),
                  const SizedBox(height: 10),
                  _SecondaryButton(label: 'Log in', onTap: () => _goToLogin(context)),
                  const SizedBox(height: 12),
                  const _TermsFootnote(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _Hero extends StatelessWidget {
  final String locationLabel;
  final VoidCallback? onChangeLocation;

  const _Hero({required this.locationLabel, this.onChangeLocation});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeroCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 54),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF3E3690)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'DigitalAds',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -.2),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onChangeLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 96),
                            child: Text(
                              locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Discover local.\nEarn real rewards.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Nearby offers from real local businesses — answer a quick '
                    'quiz on each ad and the winnings land in your wallet.',
                style: TextStyle(color: Colors.white.withOpacity(.82), fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 36)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ============================================================
// SEARCH BAR
// ============================================================

class _SearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  const _SearchBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search for ads, shops, offers...',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.tune_rounded, size: 15, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORY STRIP
// ============================================================

class _CategoryStrip extends StatelessWidget {
  final ValueChanged<String>? onTap;
  const _CategoryStrip({this.onTap});

  // Placeholder categories matching a general local-ads marketplace.
  // Wire onTap to your actual ad filtering once ads carry a category field.
  static const _categories = [
    (Icons.checkroom_rounded, 'Fashion'),
    (Icons.devices_rounded, 'Electronics'),
    (Icons.build_rounded, 'Services'),
    (Icons.fastfood_rounded, 'Food'),
    (Icons.home_work_rounded, 'Real Estate'),
    (Icons.grid_view_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return GestureDetector(
            onTap: () => onTap?.call(category.$2),
            child: SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(14)),
                    child: Icon(category.$1, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.$2,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// POST AD BANNER
// ============================================================

class _PostAdBanner extends StatelessWidget {
  final VoidCallback? onTap;
  const _PostAdBanner({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF6C5FD1)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selling something local?',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
                ),
                const SizedBox(height: 5),
                Text(
                  'Put your ad in front of buyers near you.',
                  style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 11.5, height: 1.4),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Post an ad', style: TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16), shape: BoxShape.circle),
            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BUTTONS
// ============================================================

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SecondaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _TermsFootnote extends StatelessWidget {
  const _TermsFootnote();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, height: 1.5),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(text: 'Terms', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}