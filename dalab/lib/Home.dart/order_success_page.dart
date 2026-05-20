import 'package:dalab/Home.dart/homepage.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderSuccessPage extends StatefulWidget {
  final String orderId;
  const OrderSuccessPage({super.key, required this.orderId});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('orders')
              .stream(primaryKey: ['id'])
              .eq('id', widget.orderId),
          builder: (context, snapshot) {
            int currentStep = 0; // Default to Pending (0 steps active)
            String shortOrderId = widget.orderId.substring(0, 5).toUpperCase();
            String formattedOrderNum = "#ORD-$shortOrderId";

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final status = snapshot.data!.first['status'] as String?;
              if (status == 'Accepted') currentStep = 1;
              if (status == 'Cooking') currentStep = 2;
              if (status == 'On The Way') currentStep = 3;
              if (status == 'Arrived') currentStep = 4;
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(Icons.check, color: Colors.green, size: 40),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Dalabka waa la helay!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Mahadsanid! Dalabkaaga waa la diiwaangeliyay.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long, color: Colors.deepOrange),
                                SizedBox(width: 12),
                                Text(
                                  "Order Number",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              formattedOrderNum,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.deepOrange),
                                SizedBox(width: 12),
                                Text(
                                  "Delivery Time",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "30 - 45 min",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payments, color: Colors.deepOrange),
                                SizedBox(width: 12),
                                Text(
                                  "Payment",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Cash",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.orange.shade100),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tracking Number  $formattedOrderNum",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            SizedBox(
                              width: 64,
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: currentStep >= 1
                                        ? Colors.deepOrange
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      Icons.task_alt,
                                      color: currentStep >= 1
                                          ? Colors.white
                                          : Colors.deepOrange,
                                      size: 22,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  FittedBox(
                                    child: Text(
                                      "Accepted",
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 3,
                                color: currentStep >= 2
                                    ? Colors.deepOrange
                                    : Colors.orange.shade100,
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: currentStep >= 2
                                        ? Colors.deepOrange
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      Icons.restaurant,
                                      color: currentStep >= 2
                                          ? Colors.white
                                          : Colors.deepOrange,
                                      size: 22,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  FittedBox(
                                    child: Text(
                                      "Cooking",
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 3,
                                color: currentStep >= 3
                                    ? Colors.deepOrange
                                    : Colors.orange.shade100,
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: currentStep >= 3
                                        ? Colors.deepOrange
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      Icons.delivery_dining,
                                      color: currentStep >= 3
                                          ? Colors.white
                                          : Colors.deepOrange,
                                      size: 22,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  FittedBox(
                                    child: Text(
                                      "On The Way",
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 3,
                                color: currentStep >= 4
                                    ? Colors.deepOrange
                                    : Colors.orange.shade100,
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: currentStep >= 4
                                        ? Colors.deepOrange
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      Icons.home,
                                      color: currentStep >= 4
                                          ? Colors.white
                                          : Colors.deepOrange,
                                      size: 22,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  FittedBox(
                                    child: Text(
                                      "Arrived",
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28),
                  Text(
                    "Waan kula soo xiriiri doonaa dhawaan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => Homepage()),
                          (route) => false,
                        );
                      },
                      icon: Icon(Icons.home),
                      label: Text(
                        "Back to Home",
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
