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

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(),

      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Auto Verified Successfully")));
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
            builder: (_) => OTPPage(
              verificationId: verificationId,
              phone: phoneController.text.trim(),
            ),
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
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 80, left: 20, right: 20),
          child: Column(
            children: [
              SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Form(
                  key: LoginFormKey,
                  child: Container(
                    margin: EdgeInsets.only(top: 50, left: 15, right: 15),
                    child: Column(
                      children: [
                        Image.asset(
                          "images/logo.png",
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Sign in with your phone number",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 40),

                        // ================= PHONE =================
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter phone number";
                            }
                            if (!value.startsWith("+")) {
                              return "Use format +252...";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "+252xxxxxxxxx",
                            prefixIcon: Icon(
                              Icons.phone,
                              color: Colors.deepOrange,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepOrange),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepOrange),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.deepOrange,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        SizedBox(height: 40),

                        // ================= BUTTON =================
                        ElevatedButton(
                          onPressed: isLoading ? null : sendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                                  MaterialPageRoute(builder: (_) => Signup()),
                                );
                              },
                              child: Text(
                                "Sign up",
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
