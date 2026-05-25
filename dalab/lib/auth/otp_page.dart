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
        String nameToSave = "";
        if (widget.name != null && widget.name!.isNotEmpty) {
          nameToSave = widget.name!.trim().split(RegExp(r'\s+')).map((w) {
            if (w.isEmpty) return '';
            return w[0].toUpperCase() + w.substring(1).toLowerCase();
          }).join(' ');
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          String rawDisplayName = user.displayName!;
          if (rawDisplayName.contains('|')) {
            rawDisplayName = rawDisplayName.split('|')[0];
          }
          nameToSave = rawDisplayName.trim().split(RegExp(r'\s+')).map((w) {
            if (w.isEmpty) return '';
            return w[0].toUpperCase() + w.substring(1).toLowerCase();
          }).join(' ');
        }

        // Save formatted join date for new signups
        final now = DateTime.now();
        final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        final formattedDate = "${now.day} ${months[now.month - 1]}, ${now.year}";
        await prefs.setString('joined_date', formattedDate);

        // Save to Supabase 'users' table
        try {
          Map<String, dynamic>? existingRecord;
          try {
            existingRecord = await Supabase.instance.client
                .from('users')
                .select('name, district')
                .eq('id', user.uid)
                .maybeSingle();
          } catch (_) {
            existingRecord = await Supabase.instance.client
                .from('users')
                .select('name')
                .eq('id', user.uid)
                .maybeSingle();
          }

          String finalNameToSave = nameToSave;
          if (finalNameToSave.isEmpty && existingRecord != null && existingRecord['name'] != null) {
            finalNameToSave = existingRecord['name'].toString();
          }

          String finalDistrictToSave = "";
          if (existingRecord != null && existingRecord.containsKey('district') && existingRecord['district'] != null) {
            finalDistrictToSave = existingRecord['district'].toString();
          }

          if (finalDistrictToSave.isNotEmpty) {
            await prefs.setString('selected_district', finalDistrictToSave);
          }

          if (finalNameToSave.isNotEmpty) {
            final combinedName = finalDistrictToSave.isNotEmpty
                ? "$finalNameToSave|$finalDistrictToSave"
                : finalNameToSave;
            await user.updateDisplayName(combinedName);
            await user.reload();
            await prefs.setString('profile_name', finalNameToSave);
          } else if (finalDistrictToSave.isNotEmpty) {
            await user.updateDisplayName("|$finalDistrictToSave");
            await user.reload();
          }

          final Map<String, dynamic> upsertData = {
            'id': user.uid,
            'phone': user.phoneNumber,
          };

          if (finalNameToSave.isNotEmpty) {
            upsertData['name'] = finalNameToSave;
          }
          if (finalDistrictToSave.isNotEmpty) {
            upsertData['district'] = finalDistrictToSave;
          }

          if (existingRecord == null) {
            upsertData['created_at'] = user.metadata.creationTime?.toIso8601String() ?? DateTime.now().toIso8601String();
          }

          try {
            await Supabase.instance.client.from('users').upsert(upsertData);
          } catch (_) {
            if (upsertData.containsKey('district')) {
              upsertData.remove('district');
              await Supabase.instance.client.from('users').upsert(upsertData);
            }
          }
        } catch (supabaseError) {
          print("Supabase user save error (table might not exist yet): $supabaseError");
          if (nameToSave.isNotEmpty) {
            await user.updateDisplayName(nameToSave);
            await prefs.setString('profile_name', nameToSave);
          }
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
        border: Border.all(
          color: focusNodes[index].hasFocus
              ? Colors.black
              : Colors.grey.shade200,
          width: 1.5,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                            "images/logo.jpeg",
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "images/logo.png",
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
                      "Xaqiiji Telefoonkaaga",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Waxaan SMS u dirnay lambarka:",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Fadlan geli code-ka xaqiijinta ee laguu soo diray.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ================= OTP BOXES =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, otpBox),
                    ),

                    // Spacer wuxuu ku riixayaa badhanka iyo linkiga hoos
                    const Spacer(),
                    const SizedBox(height: 30),

                    // ================= VERIFY BUTTON (FLAT BLACK) =================
                    isVerifying
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: verifyOTP,
                            child: const Text(
                              "Verify",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),

                    // ================= COUNTDOWN & RESEND LINK =================
                    Center(
                      child: Column(
                        children: [
                          Text(
                            seconds > 0
                                ? "Wuxuu dhacayaa: ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}"
                                : "Code-ku waa dhacay",
                            style: TextStyle(
                              fontSize: 14,
                              color: seconds > 0 ? Colors.black54 : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: seconds == 0 ? resendOTP : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black87,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Resend OTP",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: seconds == 0 ? Colors.black87 : Colors.grey,
                                decoration: TextDecoration.underline,
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
