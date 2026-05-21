import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BonusWalletPage extends StatefulWidget {
  const BonusWalletPage({super.key});

  @override
  State<BonusWalletPage> createState() => _BonusWalletPageState();
}

class _BonusWalletPageState extends State<BonusWalletPage> {
  double bonusBalance = 150.00; // Default mock bonus
  String userName = "Mohamed Ali";
  final TextEditingController cardController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('profile_name') ?? "Mohamed Ali";
      bonusBalance = prefs.getDouble('bonus_balance') ?? 150.00;
    });
  }

  Future<void> _withdrawBonus() async {
    if (!_formKey.currentState!.validate()) return;

    final double withdrawAmount = double.tryParse(amountController.text) ?? 0.0;
    if (withdrawAmount > bonusBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Boniska aad haysato ayaa ka yar inta aad codsatay!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bonusBalance -= withdrawAmount;
    });
    await prefs.setDouble('bonus_balance', bonusBalance);

    cardController.clear();
    amountController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Masha Allah, \$${withdrawAmount.toStringAsFixed(2)} waxaa lagu shubay kaarkaaga!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    cardController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
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
                        color: const Color(0xFFFF6D24).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
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
                          // Restaurant Logo simulation on the left
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Color(0xFFFF6D24),
                                  size: 22,
                                ),
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
                        "\$${bonusBalance.toStringAsFixed(2)}",
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
                          const Text(
                            "**** **** **** 3264",
                            style: TextStyle(
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

                // 2. WITHDRAW SECTION TITLE
                const Text(
                  "Withdraw",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Ku shubo boniskaaga kaarkaaga rasmiga ah (Physical Card) si aad lacag la'aan wax ugu iibsato maqaayadda dhexdeeda.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // 3. PHYSICAL CARD NUMBER FIELD
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
                  decoration: InputDecoration(
                    hintText: "Geli 16-ka nambar ee kaarka",
                    prefixIcon: const Icon(CupertinoIcons.creditcard, color: Color(0xFFFF6D24)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
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
                const SizedBox(height: 20),

                // 4. AMOUNT TO WITHDRAW FIELD
                const Text(
                  "Cadadka aad la baxayso (Amount)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Tusaale: 50",
                    prefixIcon: const Icon(CupertinoIcons.money_dollar, color: Color(0xFFFF6D24)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Fadlan qor cadadka aad la baxayso!";
                    }
                    final amt = double.tryParse(value);
                    if (amt == null || amt <= 0) {
                      return "Fadlan geli cadad sax ah oo ka weyn 0!";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 5. WITHDRAW BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _withdrawBonus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D24),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "La Bax Boniska (Withdraw)",
                      style: TextStyle(
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
