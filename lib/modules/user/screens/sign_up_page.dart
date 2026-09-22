import 'package:digitalads/modules/user/screens/user_login_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(const SignUpPage());


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  static const Color primaryBlue = Color(0xFF1450E8);
  static const Color darkBlue = Color(0xFF0B3ABF);
  static const Color orange = Color(0xFFFF7A1A);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(context),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildCategories(),
              const SizedBox(height: 24),
              _buildPostAdBanner(),
              const SizedBox(height: 24),
              _buildTrustRow(),
              const SizedBox(height: 24),
              _buildActionButtons(context),
              const SizedBox(height: 16),
              _buildFooterText(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HERO SECTION ----------------
  Widget _buildHeroSection(BuildContext context) {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFF3FF), Color(0xFFD9E4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar: logo + location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: SignUpPage.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                            children: [
                              TextSpan(text: 'Local'),
                              TextSpan(
                                  text: 'Ads',
                                  style: TextStyle(color: SignUpPage.primaryBlue)),
                            ],
                          ),
                        ),
                        const Text(
                          'Discover. Connect. Grow Local.',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, color: SignUpPage.primaryBlue, size: 16),
                      SizedBox(width: 4),
                      Text('Bangalore, India',
                          style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Headline + phone mockup
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your City.',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      const Text('Your Deals.',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: SignUpPage.primaryBlue)),
                      const Text('Your Way.',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: SignUpPage.orange)),
                      const SizedBox(height: 10),
                      const Text(
                        'Find the best local businesses, amazing offers and services near you.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _buildPhoneMockup(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneMockup() {
    return AspectRatio(
      aspectRatio: 0.55,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF14213D),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello, 👋', style: TextStyle(fontSize: 9)),
                const Text('What are you looking for?',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, size: 10, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text('Search businesses...',
                            style: TextStyle(fontSize: 7, color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEF9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.location_on, color: SignUpPage.primaryBlue, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(4, (i) {
                    final icons = [
                      Icons.restaurant,
                      Icons.storefront,
                      Icons.build,
                      Icons.apartment
                    ];
                    return Expanded(
                      child: Icon(icons[i], size: 12, color: SignUpPage.primaryBlue),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Flat 20% OFF',
                          style:
                          TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                      Text('on All Food Orders',
                          style: TextStyle(fontSize: 6, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: SignUpPage.primaryBlue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Search for shops, services, deals...',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune, size: 20),
          ),
        ],
      ),
    );
  }

  // ---------------- CATEGORIES ----------------
  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.restaurant, 'label': 'Food & Dining', 'color': const Color(0xFFFFEFE0)},
      {'icon': Icons.shopping_bag, 'label': 'Shopping', 'color': const Color(0xFFF0E9FB)},
      {'icon': Icons.build, 'label': 'Services', 'color': const Color(0xFFE3F6E9)},
      {'icon': Icons.apartment, 'label': 'Real Estate', 'color': const Color(0xFFE3ECFB)},
      {'icon': Icons.local_offer, 'label': 'Offers', 'color': const Color(0xFFFCE4EC)},
      {'icon': Icons.grid_view, 'label': 'View All', 'color': const Color(0xFFECECEC)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Explore Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 4,
            childAspectRatio: 0.7,
            children: categories.map((c) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: c['color'] as Color,
                    child: Icon(c['icon'] as IconData,
                        color: SignUpPage.primaryBlue, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------- POST AD BANNER ----------------
  Widget _buildPostAdBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Post Your Ad',
                      style: TextStyle(
                          color: SignUpPage.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      children: [
                        TextSpan(text: 'Grow Your Business With '),
                        TextSpan(
                            text: 'Local Ads',
                            style: TextStyle(color: SignUpPage.primaryBlue)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reach thousands of local customers and grow your business.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SignUpPage.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: const Row(
                      children: [
                        Text('Post Ad Now'),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_outward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                children: const [
                  Icon(Icons.campaign, size: 48, color: SignUpPage.primaryBlue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TRUST ROW ----------------
  Widget _buildTrustRow() {
    final items = [
      {
        'icon': Icons.verified_user,
        'title': 'Trusted & Safe',
        'subtitle': 'Verified businesses and secure platform',
        'color': const Color(0xFFE3ECFB),
        'iconColor': SignUpPage.primaryBlue,
      },
      {
        'icon': Icons.location_on,
        'title': 'Near You',
        'subtitle': 'Find the best near your location',
        'color': const Color(0xFFE3F6E9),
        'iconColor': Colors.green,
      },
      {
        'icon': Icons.percent,
        'title': 'Best Offers',
        'subtitle': 'Exciting deals & offers from local businesses',
        'color': const Color(0xFFFFF0E5),
        'iconColor': SignUpPage.orange,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: item['color'] as Color,
                  child: Icon(item['icon'] as IconData,
                      color: item['iconColor'] as Color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(item['subtitle'] as String,
                          style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- ACTION BUTTONS ----------------
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: SignUpPage.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: () { Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              UserLoginScreen()));

                    }, child: const Text('Get Started',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,color: Colors.white),),),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: SignUpPage.primaryBlue,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Login',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooterText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(fontSize: 11, color: Colors.grey),
          children: [
            TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
                text: 'Terms & Conditions',
                style: TextStyle(color: SignUpPage.primaryBlue)),
            TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: TextStyle(color: SignUpPage.primaryBlue)),
          ],
        ),
      ),
    );
  }
}

// Curved bottom edge for the hero section, like the design's wave shape.
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}