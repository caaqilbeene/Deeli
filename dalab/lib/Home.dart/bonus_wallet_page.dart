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
  double bonusBalance = 150.00; // Default mock bonus
  String userName = "Mohamed Ali";
  String? localLogoPath;
  String? remoteLogoUrl;
  String? linkedCardNumber; // Fetched from Supabase

  bool isUploadingLogo = false;
  bool isLoadingData = true;
  bool isProcessingAction = false;

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
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select('bonus_balance, linked_card')
            .eq('id', user.uid)
            .maybeSingle();

        if (data != null) {
          final double dbBalance = (data['bonus_balance'] as num?)?.toDouble() ?? bonusBalance;
          final String? dbCard = data['linked_card'] as String?;

          setState(() {
            bonusBalance = dbBalance;
            linkedCardNumber = dbCard;
            if (dbCard != null) {
              cardController.text = dbCard;
            }
          });

          await prefs.setDouble('bonus_balance', dbBalance);
          if (dbCard != null) {
            await prefs.setString('linked_card_number', dbCard);
          } else {
            await prefs.remove('linked_card_number');
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

    final String inputCard = cardController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isProcessingAction = true;
    });

    try {
      // 1. Verify card exists and is available
      final cardData = await Supabase.instance.client
          .from('physical_cards')
          .select('status')
          .eq('card_number', inputCard)
          .maybeSingle();

      if (cardData == null) {
        throw "Kaarka nambarkaas leh laguma hayo diiwaanka maqaayadda!";
      }

      final String status = cardData['status'];
      if (status != 'available') {
        throw "Kaarkaan mar hore ayaa la isticmaalay ama waa la xannibay!";
      }

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
                      // 1. PREMIUM ORANGE CARD
                      Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6D24), Color(0xFFFF8E53)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6D24).withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Restaurant Logo on the left
                                GestureDetector(
                                  onTap: _pickAndUploadLogo,
                                  child: Row(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
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
                                                      size: 22,
                                                    ),
                                            ),
                                          ),
                                          if (isUploadingLogo)
                                            const SizedBox(
                                              width: 44,
                                              height: 44,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D24)),
                                              ),
                                            )
                                          else
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
                                                  size: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "DEELI",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Card indicator text
                                const Text(
                                  "LOYALTY CARD",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Bonus Balance Display
                            const Text(
                              "Bonus Balance",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bonusBalance.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Card details bottom row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  userName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  hasLinkedCard
                                      ? linkedCardNumber!
                                      : "**** **** **** 3264",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 2. ACTION SECTION
                      Text(
                        hasLinkedCard ? "Withdraw" : "Link Physical Card",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasLinkedCard
                            ? "Ku shubo boniskaaga kaarkaaga rasmiga ah (Physical Card) si aad lacag la'aan wax ugu iibsato maqaayadda dhexdeeda."
                            : "Geli 16-ka nambar ee kaarka physical-ka ah si aad ugu xirato koontadaada abka oo aad boniska ugu shubato.",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. CARD NUMBER FIELD
                      const Text(
                        "Nambarka Kaarka (Card Number)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: cardController,
                        keyboardType: TextInputType.number,
                        enabled: !hasLinkedCard, // Disable if already linked
                        decoration: InputDecoration(
                          hintText: "Geli 16-ka nambar ee kaarka",
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
                          if (value.trim().length < 8) {
                            return "Nambarka kaarka aad buu u gaaban yahay!";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // 4. ACTION BUTTON (Link Card or Withdraw)
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
