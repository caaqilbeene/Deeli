/*
import 'package:dalab/Home.dart/homepage.dart';
import 'package:dalab/auth/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  // ANALYZE INFO: Variable name should be lowerCamelCase: loginFormKey.
  final LoginFormKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPassword = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> logIn() async {
    if (!LoginFormKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      User? user = userCredential.user;
      if (user != null) {
        await user.reload();
        if (!user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Fadlan xaqiiji email-kaaga")),
            );
          }
          return;
        }
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Khalad ayaa dhacay";
      if (e.code == "user-not-found") {
        message = "Email-kaan lama helin";
      } else if (e.code == "wrong-password") {
        message = "password ka waa qalad";
      } else if (e.code == "invalid-email") {
        message = "Email-ku waa khaldan yahay";
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.only(top: 100, left: 30, right: 30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: MediaQuery.of(context).size.height / 1.2,
                  width: MediaQuery.of(context).size.width,
                  child: Form(
                    key: LoginFormKey,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 30),
                          Image.asset(
                            "images/logo.png",
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 40),
                          Text(
                            "Sign in",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1550A9),
                            ),
                          ),
                          Text(
                            "Sign in with your email and password.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter your email";
                              }
                              if (!value.contains("@") ||
                                  !value.contains(".")) {
                                return "Enter valid email";
                              }
                              if (value.contains(" ")) {
                                return "Email ka looma ogola firaaqo u dhexeeyo";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Email address",
                              prefixIcon: Icon(
                                Icons.mail,
                                color: Color(0xFF1550A9),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                              fillColor: Colors.grey.shade100,
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !isPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Midkood ayaa qaldan email ka ama Password ka";
                              }
                              if (value.length < 8) {
                                return "Password waa inuu ahaadaa ugu yaraan 8 xaraf";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Password",
                              prefixIcon: Icon(
                                Icons.password,
                                color: Color(0xFF1550A9),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPassword = !isPassword;
                                  });
                                },

                                icon: Icon(
                                  isPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xFF1550A9),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade100,
                                ),
                              ),
                              fillColor: Colors.grey.shade100,
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                },
                                child: Text(
                                  "Forgot your password?",
                                  style: TextStyle(color: Color(0xFF1550A9)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading ? null : logIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1550A9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: Size(double.infinity, 50),
                            ),

                            child: isLoading
                                ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : Text(
                                    "Continue",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?"),
                              SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Signup(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Sign up",
                                  style: TextStyle(color: Color(0xFF1550A9)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

import 'package:dalab/Home.dart/homepage.dart';
import 'package:dalab/auth/signup.dart';
import 'package:dalab/auth/otp_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  final LoginFormKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  // ================= SEND OTP =================
  Future<void> sendOTP() async {
    if (!LoginFormKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // ================= PHONE NUMBER FORMATTING (FORMATKA TELEFOONKA) =================
    // Haddii user-ku uu qoro lambarka isagoo aan wadan +252, waxaan u habeyneynaa inaan ku darno +252.
    // Sidoo kale haddii uu lambarku ku bilaabmo eber '0', waa laga saarayaa eberka ka hor intaan +252 lagu darin.
    String inputPhone = phoneController.text.trim();
    String finalPhone = inputPhone;
    if (!inputPhone.startsWith("+")) {
      if (inputPhone.startsWith("0")) {
        inputPhone = inputPhone.substring(1);
      }
      finalPhone = "+252$inputPhone";
    }

    // ================= CHECK USER EXISTS IN DATABASE =================
    try {
      final existingUser = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('phone', finalPhone)
          .maybeSingle();

      if (existingUser == null) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Akoon-kan ma jiro. Fadlan marka hore is-diiwaangeli.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e) {
      print("Error checking user existence: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: finalPhone,

      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Si toos ah ayaa loo xaqiijiyay")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
      },

      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() => isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OTPPage(verificationId: verificationId, phone: finalPhone),
          ),
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        if (!mounted) return;
        setState(() => isLoading = false);
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // ================= HEADER: CENTERING LOGO =================
                    Center(
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            // =============================================
                            // 🖼️ LOGADA LOGIN PAGE
                            // Haddaad rabto inaad logo beddesho:
                            // 1. Sawirkaaga cusub ku dhig: images/ folder
                            // 2. Magacaas halkan ku qor (hoos)
                            // =============================================
                            "images/logo.jpeg", // ← HALKAN KA BEDDEL
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "images/logo.png", // ← Backup logo (haddii kore furo waayo)
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 65),

                    // ================= HEADINGS =================
                    const Text(
                      "Ku soo dhawaada!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "ku gal lambarkaaga telefoonka",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 35),

                    // ================= FORM =================
                    Form(
                      key: LoginFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label-ka sare ee telefoonka (Geli lambarkaaga)
                          const Text(
                            "Geli lambarkaaga",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ================= PHONE FIELD WITH SOMALI FLAG =================
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Geli lambarkaaga telefoonka";
                              }
                              String val = value.trim();
                              if (val.startsWith("+")) {
                                if (!val.startsWith("+252")) {
                                  return "Fadlan isticmaal lambar Somali ah (+252)";
                                }
                                val = val.substring(4);
                              } else if (val.startsWith("0")) {
                                val = val.substring(1);
                              }
                              if (val.length < 7 || val.length > 10) {
                                return "Fadlan geli lambar telefoon oo sax ah";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "6XXXXXXXX",
                              hintStyle: const TextStyle(color: Colors.black38),
                              // Prefix-ka calanka Soomaaliya, arrow-ka, iyo code-ka +252
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4189DD),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: Colors.black54,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 1,
                                      height: 22,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "+252",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.deepOrange,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black87,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spacer wuxuu ku riixayaa badhanka iyo linkiga qaybta hoose ee shaashadda (sida mockup-ka)
                    const Spacer(),
                    const SizedBox(height: 30),

                    // ================= CONTINUE BUTTON (FLAT BLACK) =================
                    ElevatedButton(
                      onPressed: isLoading ? null : sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        disabledBackgroundColor:
                            Colors.black, // Wali madow marka loading
                        disabledForegroundColor: Colors.white, // Spinner cadaan
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Continue",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // ================= DIIWAANGELI LINK (NOW BELOW THE BUTTON) =================
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Ma laha koonto? ",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Signup(),
                                ),
                              );
                            },
                            child: const Text(
                              "Is-diiwaangeli",
                              style: TextStyle(
                                color:
                                    Colors.black87, // Black link as requested
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration
                                    .underline, // Underlined for premium link feel
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
