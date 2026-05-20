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
  final TextEditingController PasswordController = TextEditingController();
  final TextEditingController ConfirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool isPassword = false;
  bool isConfirmPassword = false;

  @override
  void dispose() {
    FullNameController.dispose();
    phoneController.dispose();
    PasswordController.dispose();
    ConfirmPasswordController.dispose();
    super.dispose();
  }

  // ================= SEND OTP =================
  Future<void> sendOTP() async {
    if (!SignUpFormKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(),

      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);

        // ANALYZE INFO: context is used after await; app can work, but mounted check is safer.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Auto Verified")));
      },

      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
      },

      codeSent: (String verificationId, int? resendToken) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPPage(
              verificationId: verificationId,
              phone: phoneController.text.trim(),
              name: FullNameController.text.trim(),
            ),
          ),
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    setState(() => isLoading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),
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
                  key: SignUpFormKey,
                  child: Container(
                    margin: EdgeInsets.only(top: 50, left: 15, right: 15),
                    child: Column(
                      children: [
                        Image.asset("images/logo.png", width: 90, height: 90),
                        SizedBox(height: 20),

                        Text(
                          "Create your account",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: FullNameController,
                          // ===== NAME AUTO CAPITALIZATION START =====
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
                          // ===== NAME AUTO CAPITALIZATION END =====
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Full Name";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Full Name",
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.deepOrange,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepOrange),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

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
                          ),
                        ),

                        SizedBox(height: 20),

                        // ================= PASSWORD =================
                        TextFormField(
                          controller: PasswordController,
                          obscureText: !isPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter password";
                            }
                            if (value.length < 8) {
                              return "Min 8 characters";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Password",
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.deepOrange,
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
                                color: Colors.deepOrange,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // ================= CONFIRM PASSWORD =================
                        TextFormField(
                          controller: ConfirmPasswordController,
                          obscureText: !isConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Confirm password";
                            }
                            if (value != PasswordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Confirm password",
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.deepOrange,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isConfirmPassword = !isConfirmPassword;
                                });
                              },
                              icon: Icon(
                                isConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.deepOrange,
                              ),
                            ),
                            border: OutlineInputBorder(
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
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Send OTP",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account?"),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Sign in",
                                style: TextStyle(color: Colors.black),
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
