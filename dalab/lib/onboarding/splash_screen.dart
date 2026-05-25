import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dalab/onboarding/bicycle_animation_screen.dart';

class SplashLogoScreen extends StatefulWidget {
  const SplashLogoScreen({super.key});

  @override
  State<SplashLogoScreen> createState() => _SplashLogoScreenState();
}

class _SplashLogoScreenState extends State<SplashLogoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // ==========================================
    // ANIMATION CONFIGURATION (KALA HAGA AJISKA ANIMATION-KA)
    // ==========================================
    // _controller wuxuu maamulaa waqtiga animation-ku socdo (1.2 ilbiriqsi).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // _scaleAnimation: Logadu waxay ka bilaabmaysaa yar (0.5) waxayna ku dhammaanaysaa cabirkeeda caadiga ah (1.0).
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // _opacityAnimation: Logadu waxay ka bilaabmaysaa transparent/qarsoon (0.0) ilaa ay si buuxda u muuqato (1.0).
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Bilaab animation-ka isla markii screen-ku furmo
    _controller.forward();

    // ==========================================
    // TRANSITION TO NEXT PAGE (U GUDBIDDA SCREEN-KA XIGA)
    // ==========================================
    // Page-kani wuxuu joogayaa 2 ilbiriqsi (2000 milliseconds) ka dib wuxuu u gudbi doonaa
    // screen-ka animation-ka baaskiilka (BicycleAnimationScreen).
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BicycleAnimationScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background cadaan ah sidii aad rabtay
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          // ==========================================
          // APP LOGO SELECTION (HALKAN KA BADAL LOGADA MUSTAQBALKA)
          // ==========================================
          // Haddii aad rabto inaad badasho logada mustaqbalka, magaca sawirka ku beddel halkan hoose.
          // Waxay isku deyi doontaa inay soo qaaddo "images/logo.png". Haddii kale, waxay u dhici doontaa "images/logo.jpeg".
          child: Image.asset(
            "images/logo.jpeg",
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                "images/logo.png",
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback haddii labada sawirba la waayo si uusan appku u crash-garoobin
                  return const Text(
                    "DELI",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                      letterSpacing: 2,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
