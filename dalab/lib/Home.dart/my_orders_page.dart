import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isFirstLoad = true;
  final Map<String, String> _previousStatuses = {};

  void _checkForStatusChanges(List<Map<String, dynamic>> orders) {
    if (_isFirstLoad) {
      for (final order in orders) {
        final orderId = order['id'] as String;
        _previousStatuses[orderId] = order['status'] ?? 'Pending';
      }
      _isFirstLoad = false;
      return;
    }
    
    for (final order in orders) {
      final orderId = order['id'] as String;
      final shortId = orderId.substring(0, 5).toUpperCase();
      final currentStatus = order['status'] ?? 'Pending';
      
      if (_previousStatuses.containsKey(orderId)) {
        final oldStatus = _previousStatuses[orderId];
        if (oldStatus != currentStatus) {
          if (currentStatus == 'Accepted') {
            _showOrderAcceptedNotification(shortId);
          } else if (currentStatus == 'On The Way') {
            _showOrderOnTheWayNotification(shortId);
          } else if (currentStatus == 'Arrived') {
            _showOrderArrivedNotification(shortId);
          }
        }
      }
      _previousStatuses[orderId] = currentStatus;
    }
  }

  void _showOrderAcceptedNotification(String shortId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.deepOrange.shade50,
                  child: Icon(Icons.check_circle, color: Colors.deepOrange, size: 48),
                ),
                SizedBox(height: 20),
                Text(
                  "Dalabkaaga Waa La Aqbalay! 🎉",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Dalabkaaga #ORD-$shortId waa la aqbalay. Jikada ayaa hadda bilaabay diyaarinta cuntadaada!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Hagaag",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderOnTheWayNotification(String shortId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.delivery_dining, color: Colors.blue, size: 48),
                ),
                SizedBox(height: 20),
                Text(
                  "Dalabkaaga Waa Soo Baxay! 🚴",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Dalabkaaga #ORD-$shortId wuxuu ku jiraa waddada. Darawalka ayaa kuu soo wada!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Hagaag",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderArrivedNotification(String shortId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.green.shade50,
                  child: Icon(Icons.home, color: Colors.green, size: 48),
                ),
                SizedBox(height: 20),
                Text(
                  "Dalabkaaga Waa Soo Gaaray! 🏡",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Dalabkaaga #ORD-$shortId wuxuu soo gaaray bartaada gaarsiinta. Fadlan la kulan darawalka!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Hagaag",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderTrackingBottomSheet(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final shortId = orderId.substring(0, 5).toUpperCase();
    final status = order['status'] ?? 'Pending';
    final totalAmount = order['total_amount'] ?? 0.0;
    
    int activeStep = 0; // 0: Placed, 1: Accepted, 2: Cooking, 3: On The Way, 4: Arrived
    if (status == 'Accepted') {
      activeStep = 1;
    } else if (status == 'Cooking') {
      activeStep = 2;
    } else if (status == 'On The Way') {
      activeStep = 3;
    } else if (status == 'Arrived') {
      activeStep = 4;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order Tracking",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Order ID: #ORD-$shortId",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 28),
                  
                  _buildTrackingStep(
                    title: "Order Placed",
                    subtitle: "Dalabkaaga waa la diray oo waa la helay",
                    isActive: activeStep >= 0,
                    isCompleted: activeStep > 0,
                    icon: Icons.assignment_turned_in,
                  ),
                  _buildTimelineConnector(activeStep > 0),
                  
                  _buildTrackingStep(
                    title: "Order Accepted",
                    subtitle: "Maqaayadda ayaa aqbashay dalabkaaga",
                    isActive: activeStep >= 1,
                    isCompleted: activeStep > 1,
                    icon: Icons.check_circle,
                  ),
                  _buildTimelineConnector(activeStep > 1),
                  
                  _buildTrackingStep(
                    title: "Preparing Food",
                    subtitle: "Jikada ayaa hadda diyaarinaysa cuntadaada",
                    isActive: activeStep >= 2,
                    isCompleted: activeStep > 2,
                    icon: Icons.restaurant,
                  ),
                  _buildTimelineConnector(activeStep > 2),
                  
                  _buildTrackingStep(
                    title: "On The Way",
                    subtitle: "Darawalka ayaa soo wada cuntadaada",
                    isActive: activeStep >= 3,
                    isCompleted: activeStep > 3,
                    icon: Icons.delivery_dining,
                  ),
                  _buildTimelineConnector(activeStep > 3),
                  
                  _buildTrackingStep(
                    title: "Arrived",
                    subtitle: "Dalabkaaga wuxuu soo gaaray bartaada",
                    isActive: activeStep >= 4,
                    isCompleted: activeStep >= 4,
                    icon: Icons.home,
                  ),
                  
                  if (order['rider_name'] != null && order['rider_name'].toString().isNotEmpty) ...[
                    SizedBox(height: 18),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.delivery_dining, color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Darawalka Dalabka",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  order['rider_name'].toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (order['rider_phone'] != null && order['rider_phone'].toString().isNotEmpty) ...[
                                  SizedBox(height: 1),
                                  Text(
                                    order['rider_phone'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (order['rider_phone'] != null && order['rider_phone'].toString().isNotEmpty)
                            InkWell(
                              onTap: () async {
                                final phone = order['rider_phone'].toString().replaceAll(' ', '');
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: phone,
                                );
                                if (await canLaunchUrl(launchUri)) {
                                  await launchUrl(launchUri);
                                }
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.phone, color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    required IconData icon,
  }) {
    Color stepColor = isActive 
        ? (isCompleted ? Colors.green : Colors.deepOrange)
        : Colors.grey.shade300;
        
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: stepColor.withOpacity(0.1),
          child: Icon(icon, color: stepColor, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black87 : Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13, 
                  color: isActive ? Colors.black54 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool isCompleted) {
    return Container(
      margin: EdgeInsets.only(left: 23, top: 2, bottom: 2),
      width: 2,
      height: 18,
      color: isCompleted ? Colors.green : Colors.grey.shade200,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              "My Orders",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('orders')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Cillad ayaa dhacday: ${snapshot.error}"));
                }

                final orders = snapshot.data;
                if (orders != null && orders.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _checkForStatusChanges(orders);
                  });
                }

                if (orders == null || orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_text, size: 80, color: Colors.grey.shade300),
                        SizedBox(height: 16),
                        Text(
                          "Weli wax dalab ah ma sameynin",
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderId = order['id'] as String;
                    final shortId = orderId.substring(0, 5).toUpperCase();
                    final formattedOrderNum = "#ORD-$shortId";
                    final status = order['status'] ?? 'Pending';
                    final totalAmount = order['total_amount'] ?? 0.0;
                    
                    DateTime? createdAt;
                    if (order['created_at'] != null) {
                      createdAt = DateTime.tryParse(order['created_at']);
                    }

                    // Determine color based on status
                    Color statusColor = Colors.orange;
                    IconData statusIcon = Icons.timelapse;
                    
                    if (status == 'Cooking') {
                      statusColor = Colors.orange.shade700;
                      statusIcon = Icons.restaurant;
                    } else if (status == 'On The Way') {
                      statusColor = Colors.blue;
                      statusIcon = Icons.delivery_dining;
                    } else if (status == 'Arrived') {
                      statusColor = Colors.green;
                      statusIcon = Icons.home;
                    } else if (status == 'Accepted') {
                      statusColor = Colors.deepOrange;
                      statusIcon = Icons.check_circle;
                    }

                    return GestureDetector(
                      onTap: () => _showOrderTrackingBottomSheet(context, order),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formattedOrderNum,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(statusIcon, size: 14, color: statusColor),
                                        SizedBox(width: 4),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Divider(color: Colors.grey.shade200),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(CupertinoIcons.calendar, size: 18, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    createdAt != null 
                                        ? DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt)
                                        : "Unknown date",
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Total Amount",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "\$${totalAmount.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
