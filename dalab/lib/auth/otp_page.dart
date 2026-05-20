import 'package:dalab/Home.dart/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTPPage extends StatefulWidget {
  final String verificationId;
  final String phone;
  final String? name;

  const OTPPage({
    super.key,
    required this.verificationId,
    required this.phone,
    this.name,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  int seconds = 300; // 5 min
  late String currentVerificationId;
  bool isVerifying = false;

  @override
  void initState() {
    super.initState();
    currentVerificationId = widget.verificationId;
    startTimer();
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void startTimer() async {
    while (seconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => seconds--);
    }
  }

  String get code => controllers.map((e) => e.text).join();

  // ================= VERIFY =================
  Future<void> verifyOTP() async {
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fadlan dhamaystir code-ka")),
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: currentVerificationId,
        smsCode: code,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        if (widget.name != null && widget.name!.isNotEmpty) {
          await user.updateDisplayName(widget.name);
          await prefs.setString('profile_name', widget.name!);
        }

        // Save formatted join date for new signups
        final now = DateTime.now();
        final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        final formattedDate = "${now.day} ${months[now.month - 1]}, ${now.year}";
        await prefs.setString('joined_date', formattedDate);

        // Save to Supabase 'users' table
        try {
          await Supabase.instance.client.from('users').upsert({
            'id': user.uid,
            'phone': user.phoneNumber,
            'name': widget.name ?? user.displayName ?? '',
            'created_at': user.metadata.creationTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
          });
        } catch (supabaseError) {
          print("Supabase user save error (table might not exist yet): $supabaseError");
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.deepOrange,
          content: Text(
            "Verified Successfully",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isVerifying = false;
        // Clear all boxes on failure
        for (var controller in controllers) {
          controller.clear();
        }
        FocusScope.of(context).requestFocus(focusNodes[0]);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  // ================= RESEND =================
  Future<void> resendOTP() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Sending new OTP...")));

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
          (route) => false,
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Error sending OTP")),
        );
      },
      codeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          currentVerificationId = verificationId;
          seconds = 300;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("New OTP Sent!")));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Widget otpBox(int index) {
    return Container(
      width: 45, // Slightly smaller to fit 6 boxes comfortably on small screens
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ANALYZE INFO: withOpacity is deprecated; use withValues later.
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: focusNodes[index].hasFocus
              ? Colors.deepOrange
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controllers[index],
          focusNode: focusNodes[index],
          autofocus: index == 0,
          keyboardType: TextInputType.number,
          maxLength: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {}); // Update border color based on focus
            if (value.isNotEmpty) {
              if (index < 5) {
                FocusScope.of(context).requestFocus(focusNodes[index + 1]);
              } else {
                FocusScope.of(context).unfocus(); // Dismiss keyboard
                verifyOTP(); // Automatically verify
              }
            } else {
              if (index > 0) {
                FocusScope.of(context).requestFocus(focusNodes[index - 1]);
              }
            }
          },
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Very light background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Verify Your Phone",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "We've sent an SMS to:",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                widget.phone,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Enter the verification code sent to your phone number. If you can't find it, try checking your messages.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, otpBox),
              ),

              const SizedBox(height: 40),

              isVerifying
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepOrange,
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: verifyOTP,
                      child: const Text(
                        "Verify",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 30),

              Center(
                child: Column(
                  children: [
                    Text(
                      seconds > 0
                          ? "Expires in: ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}"
                          : "Code expired",
                      style: TextStyle(
                        fontSize: 15,
                        color: seconds > 0 ? Colors.black54 : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: seconds == 0 ? resendOTP : null,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.deepOrange,
                      ),
                      child: Text(
                        "Resend OTP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: seconds == 0 ? Colors.deepOrange : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
