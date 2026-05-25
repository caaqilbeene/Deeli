// import 'package:dalab/auth/loginpage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class Signup extends StatefulWidget {
//   const Signup({super.key});

//   @override
//   State<Signup> createState() => _HomePageState();
// }

// class _HomePageState extends State<Signup> {
//   final SignUpFormKey = GlobalKey<FormState>();
//   final TextEditingController EmailController = TextEditingController();
//   final TextEditingController PasswordController = TextEditingController();
//   final TextEditingController ConfirmPasswordController =
//       TextEditingController();
//   bool isLoading = false;
//   bool isPassword = false;
//   bool isConfirmPassword = false;
//   @override
//   void dispose() {
//     EmailController.dispose();
//     PasswordController.dispose();
//     ConfirmPasswordController.dispose();
//     super.dispose();
//   }

//   Future<void> SignUp() async {
//     if (!SignUpFormKey.currentState!.validate()) return;

//     setState(() => isLoading = true);

//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(
//             email: EmailController.text.trim(),
//             password: PasswordController.text.trim(),
//           );
//       await userCredential.user!.sendEmailVerification();
//       await FirebaseAuth.instance.signOut();
//       if (!mounted) return;
//       EmailController.clear();
//       PasswordController.clear();
//       ConfirmPasswordController.clear();

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Email-ka xaqiijinta waa la diray. Fadlan eeg inbox-kaaga.",
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => LoginPage()),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       if (!mounted) return;
//       String message = "Khalad ayaa dhacay";
//       if (e.code == "weak-password") {
//         message = "Password-ku waa daciif.";
//       } else if (e.code == "email-already-in-use") {
//         message = "Email-kaan horay ayaa loo diiwaan geliyay.";
//       } else if (e.code == "invalid-email") {
//         message = "Email-ka aad qortay maahan mid sax ah.";
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message), backgroundColor: Color(0xFF1550A9)),
//       );
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Container(
//           margin: EdgeInsets.only(top: 50, left: 20, right: 20),
//           child: Column(
//             children: [
//               SizedBox(height: 20),
//               Container(
//                 width: MediaQuery.of(context).size.width,
//                 height: MediaQuery.of(context).size.height / 1.2,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Form(
//                   key: SignUpFormKey,
//                   child: Container(
//                     margin: EdgeInsets.only(top: 50, left: 30, right: 30),
//                     child: Column(
//                       children: [
//                         Image.asset(
//                           "images/logo.png",
//                           width: 90,
//                           height: 90,
//                           fit: BoxFit.cover,
//                         ),
//                         SizedBox(height: 20),
//                         Text(
//                           "Create your Dalab account.",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF1550A9),
//                             //0xFF1550A9//
//                           ),
//                         ),
//                         Text(
//                           "Sign up to send and receive payments securely.",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.black54,
//                             //0xFF1550A9//
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         TextFormField(
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return "Please Enter your Email";
//                             }
//                             if (!value.contains("@") || !value.contains(".")) {
//                               return "Email is invalid Enter valid Email";
//                             }

//                             return null;
//                           },
//                           controller: EmailController,
//                           decoration: InputDecoration(
//                             hintText: "Email address",
//                             prefixIcon: Icon(
//                               Icons.mail,
//                               color: Color(0xFF1550A9),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             fillColor: Colors.grey.shade100,
//                             filled: true,
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         TextFormField(
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return "Enter Your Password";
//                             }
//                             if (value.length < 8) {
//                               return "Password should be al least 8 characters";
//                             }
//                             return null;
//                           },
//                           controller: PasswordController,
//                           obscureText: !isPassword,
//                           decoration: InputDecoration(
//                             hintText: "Password",
//                             prefixIcon: Icon(
//                               Icons.password,
//                               color: Color(0xFF1550A9),

//                               // Color(0xff107a78),
//                             ),
//                             suffixIcon: IconButton(
//                               onPressed: () {
//                                 setState(() {
//                                   isPassword = !isPassword;
//                                 });
//                               },

//                               icon: Icon(
//                                 isPassword
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                                 color: Color(0xFF1550A9),
//                               ),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             fillColor: Colors.grey.shade100,
//                             filled: true,
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         TextFormField(
//                           controller: ConfirmPasswordController,
//                           obscureText: !isConfirmPassword,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return "Confirm Your Password";
//                             }

//                             if (value.trim() !=
//                                 PasswordController.text.trim()) {
//                               return "Passwords do not match";
//                             }
//                             return null;
//                           },
//                           decoration: InputDecoration(
//                             hintText: "Confirm password",
//                             prefixIcon: Icon(
//                               Icons.password,
//                               color: Color(0xFF1550A9),
//                               // Color(0xff107a78),
//                             ),
//                             suffixIcon: IconButton(
//                               onPressed: () {
//                                 setState(() {
//                                   isConfirmPassword = !isConfirmPassword;
//                                 });
//                               },

//                               icon: Icon(
//                                 isConfirmPassword
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                                 color: Color(0xFF1550A9),
//                               ),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade100,
//                               ),
//                             ),
//                             fillColor: Colors.grey.shade100,
//                             filled: true,
//                           ),
//                         ),
//                         SizedBox(height: 40),
//                         ElevatedButton(
//                           onPressed: isLoading ? null : () => SignUp(),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color(0xFF1550A9),
//                             foregroundColor: Colors.white,
//                             minimumSize: Size(double.infinity, 50),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           child: isLoading
//                               ? SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                               : Text(
//                                   "Create account",
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                         ),
//                         SizedBox(height: 20),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text("Already have an account?"),
//                             SizedBox(width: 10),
//                             GestureDetector(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => LoginPage(),
//                                   ),
//                                 );
//                               },
//                               child: Text(
//                                 "Sign in",
//                                 style: TextStyle(color: Colors.blue.shade700),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//
import 'package:dalab/auth/loginpage.dart';
import 'package:dalab/auth/otp_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _HomePageState();
}

class _HomePageState extends State<Signup> {
  // ANALYZE INFO: Variable names below should be lowerCamelCase.
  final SignUpFormKey = GlobalKey<FormState>();
  final TextEditingController FullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    FullNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ================= SEND OTP =================
  Future<void> sendOTP() async {
    if (!SignUpFormKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // ================= PHONE NUMBER FORMATTING =================
    String inputPhone = phoneController.text.trim();
    String finalPhone = inputPhone;
    if (!inputPhone.startsWith("+")) {
      if (inputPhone.startsWith("0")) {
        inputPhone = inputPhone.substring(1);
      }
      finalPhone = "+252$inputPhone";
    }

    // ================= CHECK PHONE NUMBER UNIQUENESS =================
    try {
      final existingUser = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('phone', finalPhone)
          .maybeSingle();

      if (existingUser != null) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Lambarkan horay ayaa loo diiwaangeliyay. Fadlan dooro lambar kale.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e) {
      print("Error checking phone uniqueness: $e");
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Auto Verified")));
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
        final formattedName = _capitalizeName(FullNameController.text);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPPage(
              verificationId: verificationId,
              phone: finalPhone,
              name: formattedName,
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
                      "Sameyso Koonto",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "ku diiwaan geli lambarkaaga telefoonka",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),

                    // ================= FORM =================
                    Form(
                      key: SignUpFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- FULL NAME ---
                          const Text(
                            "Geli magacaaga oo buuxa",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: FullNameController,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) {
                              final formatted = _capitalizeName(value);
                              if (formatted == value || value.endsWith(' ')) {
                                return;
                              }
                              FullNameController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter Full Name";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Full Name",
                              hintStyle: const TextStyle(color: Colors.black38),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.black54,
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
                          const SizedBox(height: 18),

                          // --- PHONE LABEL ---
                          const Text(
                            "Geli lambarkaaga",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // --- PHONE FIELD WITH SOMALI FLAG ---
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
                              hintText: "61XXXXXXX",
                              hintStyle: const TextStyle(color: Colors.black38),
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

                    // Spacer wuxuu ku riixayaa badhanka iyo linkiga hoos ee shaashadda
                    const Spacer(),
                    const SizedBox(height: 30),

                    // ================= SEND OTP BUTTON (FLAT BLACK) =================
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
                              "Send OTP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // ================= ALREADY HAVE AN ACCOUNT LINK (NOW BELOW THE BUTTON) =================
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Horay ma u lahayd koonto? ",
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
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Soo gal",
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

  // ===== NAME AUTO CAPITALIZATION FUNCTION START =====
  String _capitalizeName(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  // ===== NAME AUTO CAPITALIZATION FUNCTION END =====
}
