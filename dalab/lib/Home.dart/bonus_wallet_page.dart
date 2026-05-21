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
  bool isAdmin = false; // Flag to restrict logo upload to admins only

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
      // Check if current user is an administrator
      final String? email = user.email;
      if (email != null) {
        final String lowerEmail = email.toLowerCase();
        if (lowerEmail == 'super@deeli.com' ||
            lowerEmail == 'staff@deeli.com' ||
            lowerEmail.endsWith('@deeli.com')) {
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
    }

    setState(() {
      isLoadingData = false;
    });
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cillad: $e"),
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
            content: Text("Cillad ka dhalatay kaydinta database-ka: $e"),
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
      logoImage = NetworkImage(remoteLogoUrl!);
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D24)),
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
                      // 1. PREMIUM CREDIT CARD (Standard Credit Card Aspect Ratio - Slimmer height 160)
                      Container(
                        width: double.infinity,
                        height: 160, // Sleeker height
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6D24), Color(0xFFFF8E53)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6D24).withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
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
                                            width: 36,
                                            height: 36,
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
                                                          const Icon(Icons.restaurant, color: Color(0xFFFF6D24)),
                                                    )
                                                  : const Icon(
                                                      Icons.restaurant,
                                                      color: Color(0xFFFF6D24),
                                                      size: 18,
                                                    ),
                                            ),
                                          ),
                                          if (isUploadingLogo)
                                            const SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D24)),
                                              ),
                                            )
                                          else if (isAdmin)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 7,
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
                                          fontSize: 15,
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
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Bonus Balance Display
                            const Text(
                              "Accumulated Bonus",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              bonusBalance.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Name and Card number stacked vertically (is hoos dhig)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
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
                                    fontSize: 12,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                      color: Color(0xFFFF6D24),
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
                        keyboardType: TextInputType.text, // Text keyboard for alphanumeric codes like D101
                        enabled: !hasLinkedCard, // Disable if already linked
                        autocorrect: false,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: "Geli 4 xaraf/nambar (Tusaale: D101)",
                          prefixIcon: const Icon(CupertinoIcons.creditcard, color: Color(0xFFFF6D24)),
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
                            backgroundColor: const Color(0xFFFF6D24),
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
