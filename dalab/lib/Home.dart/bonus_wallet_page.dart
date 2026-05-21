import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BonusWalletPage extends StatefulWidget {
  const BonusWalletPage({super.key});

  @override
  State<BonusWalletPage> createState() => _BonusWalletPageState();
}

class _BonusWalletPageState extends State<BonusWalletPage> {
  double bonusBalance = 150.00; // Virtual bonus balance
  double physicalCardBalance = 0.0; // Loaded physical card balance
  String userName = "Mohamed Ali";
  String? localLogoPath;
  String? remoteLogoUrl;
  String? linkedCardNumber; // Fetched from Supabase (e.g. D101)

  bool isUploadingLogo = false;
  bool isLoadingData = true;
  bool isProcessingAction = false;
  bool isAdmin = false; // Flag to restrict logo upload & show leaderboard to admins only
  List<Map<String, dynamic>> topCustomers = []; // Leaderboard list for Admins
  bool isLoadingTopCustomers = false;

  final TextEditingController cardController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadLocalAndRemoteData();
  }

  Future<void> _loadLocalAndRemoteData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('profile_name') ?? "Mohamed Ali";
      bonusBalance = prefs.getDouble('bonus_balance') ?? 150.00;
      localLogoPath = prefs.getString('restaurant_logo_path');
      linkedCardNumber = prefs.getString('linked_card_number');
    });

    if (linkedCardNumber != null) {
      cardController.text = linkedCardNumber!;
    }

    // Load logo URL with cache busting
    final String publicUrl = Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl('restaurant_logo.png');
    setState(() {
      remoteLogoUrl = "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    });

    // Fetch live data from Supabase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if current user is the super administrator
      final String? email = user.email;
      if (email != null) {
        final String lowerEmail = email.toLowerCase();
        if (lowerEmail == 'super@deeli.com') {
          setState(() {
            isAdmin = true;
          });
        }
      }

      try {
        final data = await Supabase.instance.client
            .from('users')
            .select('bonus_balance, linked_card, name')
            .eq('id', user.uid)
            .maybeSingle();

        if (data != null) {
          final double dbBalance = (data['bonus_balance'] as num?)?.toDouble() ?? bonusBalance;
          final String? dbCard = data['linked_card'] as String?;
          final String? dbName = data['name'] as String?;

          setState(() {
            bonusBalance = dbBalance;
            linkedCardNumber = dbCard;
            if (dbName != null && dbName.isNotEmpty) {
              userName = dbName;
            }
            if (dbCard != null) {
              cardController.text = dbCard;
            }
          });

          await prefs.setDouble('bonus_balance', dbBalance);
          if (dbName != null && dbName.isNotEmpty) {
            await prefs.setString('profile_name', dbName);
          }
          if (dbCard != null) {
            await prefs.setString('linked_card_number', dbCard);
          } else {
            await prefs.remove('linked_card_number');
          }

          // If there is a linked card, fetch its physical balance
          if (dbCard != null) {
            final cardData = await Supabase.instance.client
                .from('physical_cards')
                .select('balance')
                .eq('card_number', dbCard)
                .maybeSingle();

            if (cardData != null && cardData['balance'] != null) {
              setState(() {
                physicalCardBalance = (cardData['balance'] as num).toDouble();
              });
            }
          }
        }
      } catch (e) {
        print("Error fetching user wallet from Supabase: $e");
      }

      // If user is admin, fetch the top earners leaderboard
      if (isAdmin) {
        await _fetchTopCustomers();
      }
    }

    setState(() {
      isLoadingData = false;
    });
  }

  Future<void> _fetchTopCustomers() async {
    setState(() {
      isLoadingTopCustomers = true;
    });
    try {
      final List<dynamic> res = await Supabase.instance.client
          .from('users')
          .select('name, bonus_balance, phone')
          .order('bonus_balance', ascending: false)
          .limit(10);

      if (res.isNotEmpty) {
        setState(() {
          topCustomers = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      print("Error fetching top customers: $e");
    } finally {
      setState(() {
        isLoadingTopCustomers = false;
      });
    }
  }

  Future<void> _pickAndUploadLogo() async {
    if (!isAdmin) return; // Guard clause

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        isUploadingLogo = true;
      });

      try {
        final directory = await getApplicationDocumentsDirectory();
        final permanentFile = await File(pickedFile.path).copy(
          '${directory.path}/restaurant_logo.png',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('restaurant_logo_path', permanentFile.path);

        setState(() {
          localLogoPath = permanentFile.path;
        });

        await Supabase.instance.client.storage
            .from('avatars')
            .upload('restaurant_logo.png', permanentFile, fileOptions: const FileOptions(upsert: true));

        final String publicUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl('restaurant_logo.png');

        setState(() {
          remoteLogoUrl = "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
          isUploadingLogo = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Astaanta maqaayadda si guul leh ayaa loo beddelay!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("Error uploading restaurant logo to Supabase: $e");
        setState(() {
          isUploadingLogo = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error upload logo: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _linkPhysicalCard() async {
    if (!_formKey.currentState!.validate()) return;

    final String inputCard = cardController.text.trim().toUpperCase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isProcessingAction = true;
    });

    try {
      // 1. Verify card exists and is available
      final cardData = await Supabase.instance.client
          .from('physical_cards')
          .select('status, balance')
          .eq('card_number', inputCard)
          .maybeSingle();

      if (cardData == null) {
        throw "Kaarka nambarkaas leh laguma hayo diiwaanka maqaayadda!";
      }

      final String status = cardData['status'];
      if (status != 'available') {
        throw "Kaarkaan mar hore ayaa la isticmaalay ama waa la xannibay!";
      }

      final double initialCardBalance = (cardData['balance'] as num?)?.toDouble() ?? 0.0;

      // 2. Link the card to this user in physical_cards
      await Supabase.instance.client.from('physical_cards').update({
        'status': 'active',
        'linked_user_id': user.uid,
      }).eq('card_number', inputCard);

      // 3. Update user profile
      await Supabase.instance.client.from('users').update({
        'linked_card': inputCard,
      }).eq('id', user.uid);

      // 4. Update locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('linked_card_number', inputCard);

      setState(() {
        linkedCardNumber = inputCard;
        physicalCardBalance = initialCardBalance;
        isProcessingAction = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Masha Allah, Kaarkaaga physical-ka ah si guul leh ayaa loogu xiray koontadaada!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isProcessingAction = false;
      });
      if (mounted) {
        // User friendly Somali error messages (no database codes displayed)
        String userFriendlyError = "Fadlan geli kaar sax ah oo ka diiwaangashan maqaayadda!";
        final String errorStr = e.toString().toLowerCase();

        if (errorStr.contains("laguma hayo") || errorStr.contains("kuma jiro")) {
          userFriendlyError = "Kaarkaan kuma jiro diiwaanka. Fadlan hubi nambarka aad gelisay!";
        } else if (errorStr.contains("mar hore") || errorStr.contains("la isticmaalay")) {
          userFriendlyError = "Kaarkaan mar hore ayaa loo isticmaalay koonto kale!";
        } else if (errorStr.contains("balance does not exist")) {
          userFriendlyError = "Kaarkaan lama xaqiijin karo (balance column is missing). Fadlan la xiriir maamulka!";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _withdrawBonus() async {
    if (!_formKey.currentState!.validate()) return;

    final double withdrawAmount = bonusBalance;
    if (withdrawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ma haysatid wax bonus ah oo aad la bixi karto!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || linkedCardNumber == null) return;

    setState(() {
      isProcessingAction = true;
    });

    const double newBalance = 0.0; // Reset balance back to 0.0

    try {
      // 1. Reset user digital balance in the database
      await Supabase.instance.client.from('users').update({
        'bonus_balance': newBalance,
      }).eq('id', user.uid);

      // 2. Fetch current balance of physical card to increment it
      final cardRes = await Supabase.instance.client
          .from('physical_cards')
          .select('balance')
          .eq('card_number', linkedCardNumber!)
          .maybeSingle();

      double currentCardBalance = 0.0;
      if (cardRes != null && cardRes['balance'] != null) {
        currentCardBalance = (cardRes['balance'] as num).toDouble();
      }

      final double newCardBalance = currentCardBalance + withdrawAmount;

      // 3. Update the physical card's balance in Supabase
      await Supabase.instance.client.from('physical_cards').update({
        'balance': newCardBalance,
      }).eq('card_number', linkedCardNumber!);

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('bonus_balance', newBalance);

      setState(() {
        bonusBalance = newBalance;
        physicalCardBalance = newCardBalance;
        isProcessingAction = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Masha Allah, ${withdrawAmount.toStringAsFixed(2)} bonus oo dhan waxaa lagu shubay kaarkaaga, haddana eber (0) ayuu ka bilaabanayaa!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isProcessingAction = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cillad ka dhalatay kaydinta database-ka: Kaarkaaga lama cusboonaysiin karo."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? logoImage;
    if (localLogoPath != null && File(localLogoPath!).existsSync()) {
      logoImage = FileImage(File(localLogoPath!));
    } else if (remoteLogoUrl != null) {
      networkImageFallback() {
        return NetworkImage(remoteLogoUrl!);
      }
      logoImage = networkImageFallback();
    }

    final bool hasLinkedCard = linkedCardNumber != null && linkedCardNumber!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bonus Management",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF455A64)), // BlueGrey loader color
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. PREMIUM CREDIT CARD (Premium BlueGrey Gradient Layout)
                      Container(
                        width: double.infinity,
                        height: 140, // Ultra-slim height
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF37474F), Color(0xFF546E7A)], // Premium BlueGrey gradients
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueGrey.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Restaurant Logo on the left
                                GestureDetector(
                                  onTap: isAdmin ? _pickAndUploadLogo : null,
                                  child: Row(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: ClipOval(
                                              child: logoImage != null
                                                  ? Image(
                                                      image: logoImage,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          const Icon(Icons.restaurant, color: Color(0xFF455A64)),
                                                    )
                                                  : const Icon(
                                                      Icons.restaurant,
                                                      color: Color(0xFF455A64),
                                                      size: 16,
                                                    ),
                                            ),
                                          ),
                                          if (isUploadingLogo)
                                            const SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF455A64)),
                                              ),
                                            )
                                          else if (isAdmin)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(1),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 6,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "DEELI",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Virtual Bonus label top right
                                const Text(
                                  "VIRTUAL BONUS",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Split layout row at the bottom
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Left Column: Accumulated Bonus & Balance
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Accumulated Bonus",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      bonusBalance.toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Right Column: User Name & Card Code stacked vertically
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      userName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasLinkedCard
                                          ? linkedCardNumber!
                                          : "D000",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontFamily: 'Courier',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. PHYSICAL CARD STATUS (Only show if linked)
                      if (hasLinkedCard) ...[
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Kaarkaaga Physical-ka ah",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Active",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Nambarka:",
                                    style: TextStyle(color: Colors.black54, fontSize: 13),
                                  ),
                                  Text(
                                    linkedCardNumber!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Lacagta ku jirta (Balance):",
                                    style: TextStyle(color: Colors.black54, fontSize: 13),
                                  ),
                                  Text(
                                    physicalCardBalance.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF37474F), // Premium BlueGrey color
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 3. ACTION SECTION
                      Text(
                        hasLinkedCard ? "Withdraw to Card" : "Link Physical Card",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasLinkedCard
                            ? "Ku shubo dhammaan boniskaaga virtual-ka ah kaarkaaga physical-ka ah si aad maqaayadda uga adeegato."
                            : "Geli 4-ta xaraf/nambar ee kaarka physical-ka ah si aad ugu xirato koontadaada abka oo aad boniska ugu shubato.",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. CARD NUMBER FIELD
                      const Text(
                        "Nambarka Kaarka (Card Code)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: cardController,
                        keyboardType: TextInputType.text,
                        enabled: !hasLinkedCard,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: "Geli 4 xaraf/nambar (Tusaale: D101)",
                          prefixIcon: const Icon(CupertinoIcons.creditcard, color: Color(0xFF455A64)),
                          filled: true,
                          fillColor: hasLinkedCard ? Colors.grey.shade200 : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Fadlan geli nambarka kaarka!";
                          }
                          final trimmed = value.trim();
                          if (trimmed.length != 4) {
                            return "Nambarka kaarku waa inuu ahaadaa 4 xaraf/nambar!";
                          }
                          // Validate it starts with a letter
                          final firstChar = trimmed.substring(0, 1);
                          if (!RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
                            return "Waa inuu ku bilaabmo xaraf (Tusaale: D101)!";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // 5. ACTION BUTTON (Link Card or Withdraw)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isProcessingAction
                              ? null
                              : (hasLinkedCard ? _withdrawBonus : _linkPhysicalCard),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF37474F), // Premium BlueGrey
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isProcessingAction
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : Text(
                                  hasLinkedCard
                                      ? "La Bax Boniska (Withdraw)"
                                      : "Ku Xir Kaarka (Link Card)",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 6. ADMIN LEADERBOARD SECTION (Visible ONLY to Admins)
                      if (isAdmin) ...[
                        const Divider(height: 32),
                        const Text(
                          "Macamiisha Ugu Dhibcaha Badan (Top Customers)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Liiska 10-ka macmiil ee ugu dhibcaha badan si aad u guddoonsiiso kaarka abaalmarinta.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isLoadingTopCustomers)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF455A64)),
                              ),
                            ),
                          )
                        else if (topCustomers.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                "Weli wax macaamiil ah lama helin.",
                                style: TextStyle(color: Colors.black38),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topCustomers.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final customer = topCustomers[index];
                              final String name = customer['name'] ?? "Macmiil aan la aqoon";
                              final double balance = (customer['bonus_balance'] as num?)?.toDouble() ?? 0.0;
                              final String phone = customer['phone'] ?? "N/A";

                              // Medal or Index indicator
                              String rankPrefix = "${index + 1}. ";
                              if (index == 0) rankPrefix = "🥇 ";
                              if (index == 1) rankPrefix = "🥈 ";
                              if (index == 2) rankPrefix = "🥉 ";

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueGrey.shade50,
                                  child: Text(
                                    rankPrefix.trim(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  phone,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                trailing: Text(
                                  balance.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF37474F),
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
