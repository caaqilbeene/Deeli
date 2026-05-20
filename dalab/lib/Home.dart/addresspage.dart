import 'package:dalab/Home.dart/cart_data.dart';
import 'package:dalab/Home.dart/order_success_page.dart';
import 'package:dalab/services/supabase_service.dart';
import 'package:flutter/material.dart';

class Addresspage extends StatefulWidget {
  const Addresspage({super.key});

  @override
  State<Addresspage> createState() => _AddresspageState();
}

class _AddresspageState extends State<Addresspage> {
  String selectedCity = "Mogadishu";
  String? selectedDistrict;
  List<String> mogadishuDistricts = [
    "Abdiaziz",
    "Bondhere",
    "Daynile",
    "Dharkenley",
    "Hodan",
    "Howlwadag",
    "Huriwaa",
    "Kaxda",
    "Karaan",
    "Shangani",
    "Shibis",
    "Waberi",
    "Wadajir",
    "Wardhigley",
    "Yaaqshid",
    "Xamar Jajab",
    "Xamar Weyne",
  ]..sort();

  // ==========================================
  // QEYBTA QIIMAHA GEYNTA (DELIVERY FEE) START
  // ==========================================
  // Dhammaan degmooyinka hadda waa 0.0 (Bilaash / Free Delivery).
  // Haddii aad rabto inaad lacag ka dhigto degmo gaar ah, kaliya u beddel lacagta aad rabto (Tusaale: "Hodan": 1.50).
  Map<String, double> deliveryFees = {
    "Abdiaziz": 0.0,
    "Bondhere": 0.0,
    "Daynile": 0.0,
    "Dharkenley": 0.0,
    "Hodan": 0.0,
    "Howlwadag": 0.0,
    "Huriwaa": 0.0,
    "Kaxda": 0.0,
    "Karaan": 0.0,
    "Shangani": 0.0,
    "Shibis": 0.0,
    "Waberi": 0.0,
    "Wadajir": 0.0,
    "Wardhigley": 0.0,
    "Yaaqshid": 0.0,
    "Xamar Jajab": 0.0,
    "Xamar Weyne": 0.0,
  };

  // Variable-kaan wuxuu hayaa lacagta geynta ee xilligaas la joogo (Default waa 0.0)
  double deliveryFee = 0.0;
  // ==========================================
  // QEYBTA QIIMAHA GEYNTA (DELIVERY FEE) END
  // ==========================================

  bool isLoading = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Delivery Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),

      // ✅ Button always hoose taagan
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
        child: GestureDetector(
          onTap: () async {
            if (_formKey.currentState!.validate()) {
              setState(() {
                isLoading = true;
              });

              String? result = await SupabaseService.saveOrder(
                name: nameController.text,
                phone: phoneController.text,
                city: selectedCity,
                district: selectedDistrict!,
                details: detailsController.text,
                deliveryFee: deliveryFee,
              );

              setState(() {
                isLoading = false;
              });

              if (result != null && !result.startsWith('Error:')) {
                CartData.clearCart();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderSuccessPage(orderId: result),
                  ),
                );
              } else {
                String errorMsg =
                    result?.replaceAll('Error: ', '') ?? 'Unknown error';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cillad: $errorMsg'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          },
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Confirm Order",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),

      // ✅ Body - scroll
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              // ✅ Full Name
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text("Full Name"),
              ),
              Container(
                padding: const EdgeInsets.only(left: 10),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepOrange),
                ),
                child: TextFormField(
                  controller: nameController,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "name Required";
                    return null;
                  },
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),

              // ✅ Phone Number
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text("Phone Number"),
              ),
              Container(
                padding: const EdgeInsets.only(left: 10),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepOrange),
                ),
                child: TextFormField(
                  keyboardType: TextInputType.phone,
                  controller: phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    return null;
                  },
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),

              // ✅ City
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text("City"),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepOrange),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCity,
                  underline: const SizedBox(),
                  items: ["Mogadishu"].map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value!;
                    });
                  },
                ),
              ),

              // ✅ District
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text("District"),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepOrange),
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedDistrict,
                  hint: const Text("Select District"),
                  decoration: const InputDecoration(border: InputBorder.none),
                  validator: (value) =>
                      value == null ? "Fadlan dooro degmada" : null,
                  items: mogadishuDistricts.map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDistrict = value;
                      // Halkaan: Marka degmo cusub la doorto (value), app-ku wuxuu ka raadinayaa
                      // Map-ka kore (deliveryFees). Haddii uu waayo wuxuu ka dhigayaa $1.0 (Default).
                      if (value != null) {
                        deliveryFee = deliveryFees[value] ?? 1.0;
                      }
                    });
                  },
                ),
              ),

              // ✅ Details
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text("Details"),
              ),
              Container(
                padding: const EdgeInsets.only(left: 10),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepOrange),
                ),
                child: TextFormField(
                  controller: detailsController,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLines: 4,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),

              const SizedBox(height: 10),

              // ✅ Order Summary
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Order Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Items dynamic
              ...CartData.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Text(
                        "x${item.quantity}",
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "\$${(item.price * item.quantity).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 20, indent: 25, endIndent: 20),

              // ✅ Items count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  children: [
                    Text("Items (${CartData.cartCount})"),
                    const Spacer(),
                    Text("\$${CartData.subtotal.toStringAsFixed(2)}"),
                  ],
                ),
              ),

              // ✅ Delivery Fee
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  children: [
                    const Text("Delivery Fee"),
                    const Spacer(),
                    Text("\$${deliveryFee.toStringAsFixed(2)}"),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ✅ Total Amount
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  children: [
                    const Text(
                      "Total Amount",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      "\$${(CartData.subtotal + deliveryFee).toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
