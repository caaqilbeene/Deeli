import 'package:flutter/material.dart';
import 'package:dalab/auth/loginpage.dart';

// ==========================================
// FOOD IMAGES CONFIGURATION (HALKAN KA BEDDEL SAWIRRADA)
// ==========================================
// Haddaad rabto inaad sawirada baddashid, kaliya beddel magacyada hoos:
const List<String> _foodImages = [
  'images/burger.png', // Top-left
  'images/chicken-leg.png', // Top-right
  'images/juice.png', // Left-middle
  'images/french-fries.png', // Right-middle
  'images/shawarma.png', // Bottom-left
  'images/salad-white-clean.png', // Bottom-right (weyn oo cadaan ah)
];

// ==========================================
// FOOD IMAGE POSITIONS & ROTATIONS
// ==========================================
const List<_FoodConfig> _configs = [
  _FoodConfig(top: -20, left: -10, size: 130, rotation: -0.25), // Top-left
  _FoodConfig(top: -10, right: -15, size: 120, rotation: 0.3), // Top-right
  _FoodConfig(top: 130, left: -20, size: 110, rotation: -0.15), // Left-mid
  _FoodConfig(top: 160, right: -15, size: 115, rotation: 0.2), // Right-mid
  _FoodConfig(bottom: -15, left: 10, size: 125, rotation: 0.2), // Bottom-left
  _FoodConfig(bottom: -10, right: 5, size: 120, rotation: -0.3), // Bottom-right
];

class _FoodConfig {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double rotation;
  const _FoodConfig({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.rotation,
  });
}

class BicycleAnimationScreen extends StatefulWidget {
  const BicycleAnimationScreen({super.key});

  @override
  State<BicycleAnimationScreen> createState() => _BicycleAnimationScreenState();
}

class _BicycleAnimationScreenState extends State<BicycleAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _foodOpacity;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Logo animaation
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Cuntooyinka opacity animation
    _foodOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeIn),
      ),
    );

    // Loading bar
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // ==========================================
              // CUNTOOYINKA (FOOD IMAGES AROUND EDGES)
              // ==========================================
              // Haddaad rabto inaad sawir ku darto ama beddesho, tabo _foodImages list-ka hore
              for (int i = 0; i < _foodImages.length; i++)
                Positioned(
                  top: _configs[i].top,
                  bottom: _configs[i].bottom,
                  left: _configs[i].left,
                  right: _configs[i].right,
                  child: Opacity(
                    opacity: _foodOpacity.value,
                    child: Transform.rotate(
                      angle: _configs[i].rotation,
                      child: Image.asset(
                        _foodImages[i],
                        width: _configs[i].size,
                        height: _configs[i].size,
                        fit: BoxFit.contain,
                        // Brightness la'aan (no dim) — sawirada si cad u muuqdaan
                        errorBuilder: (context, error, stack) => SizedBox(
                          width: _configs[i].size,
                          height: _configs[i].size,
                        ),
                      ),
                    ),
                  ),
                ),

              // ==========================================
              // BARTAMAHA — LOGO + APP NAME
              // ==========================================
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              // =============================================
                              // 🖼️ LOGADA DHEXDA EE SPLASH SCREEN
                              // Haddaad rabto inaad logo beddesho:
                              // 1. Sawirkaaga cusub ku dhig: images/ folder
                              // 2. Magacaas halkan ku qor (hoos)
                              // =============================================
                              'images/logo.jpeg', // ← HALKAN KA BEDDEL
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Image.asset(
                                'images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Name
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: const Text(
                        'DAASHI',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: const Text(
                        'Food Delivery',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black38,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // LOADING BAR — HOOS (ORANGE PROGRESS BAR)
              // ==========================================
              Positioned(
                bottom: 60,
                left: size.width * 0.25,
                right: size.width * 0.25,
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Progress
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progress.value,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
