/*
import 'package:dalab/onboarding/oderfood.dart';
import 'package:flutter/material.dart';

// ANALYZE INFO: Class name should start with capital letter: Onboarding.
class onboarding extends StatefulWidget {
  const onboarding({super.key});

  @override
  State<onboarding> createState() => _onboardingState();
}

// ANALYZE INFO: State class name should start with capital letter after underscore.
class _onboardingState extends State<onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ANALYZE INFO: This Container is not required; app still works.
      body: Container(
        child: Column(
          children: [
            SizedBox(
              height: 650,
              width: 390,
              child: Image.asset(
                "images/WhatsApp Image 2026-05-14 at 14.45.26 (1).jpeg",
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Discover your favorite meals",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Find your cravings.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Orders()),
                );
              },
              child: Container(
                height: 60,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
*/
