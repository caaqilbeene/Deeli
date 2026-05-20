import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../auth/login_page.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  String _selectedStatusFilter = 'All'; // 'All', 'Pending', 'Accepted', 'Cooking', 'On The Way', 'Arrived', 'Cancelled'
  Map<String, dynamic>? _selectedOrder;
  List<Map<String, dynamic>>? _selectedOrderItems;
  bool _isLoadingItems = false;
  final List<String> _previousOrderIds = [];

  List<Map<String, dynamic>> _orders = [];
  bool _isLoadingOrders = true;
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToOrders() {
    _ordersSubscription = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
      if (mounted) {
        setState(() {
          _orders = data;
          _isLoadingOrders = false;

          // Sync the selected order details with the stream data
          if (_selectedOrder != null) {
            final matched = data.where((o) => o['id'] == _selectedOrder!['id']).toList();
            if (matched.isNotEmpty) {
              _selectedOrder = matched.first;
            }
          }
        });
      }
    }, onError: (err) {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
      debugPrint("Error listening to orders: $err");
    });
  }

  // Play a simple alert sound on new orders using system sound channels
  void _playNewOrderSound() {
    SystemSound.play(SystemSoundType.click);
  }

  Future<void> _fetchOrderItems(String orderId) async {
    setState(() {
      _isLoadingItems = true;
      _selectedOrderItems = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      // Fetch menu items to get image_path for each food item
      final menuRes = await Supabase.instance.client
          .from('menu_items')
          .select('name, image_path');

      final menuMap = {
        for (var m in menuRes)
          m['name'].toString().toLowerCase().trim(): m['image_path']
      };

      final itemsWithImages = List<Map<String, dynamic>>.from(res).map((item) {
        final nameKey = (item['item_name'] ?? '').toString().toLowerCase().trim();
        return {
          ...item,
          'image_path': menuMap[nameKey],
        };
      }).toList();

      setState(() {
        _selectedOrderItems = itemsWithImages;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
      });
      debugPrint("Error fetching order items: $e");
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dalabka status-kiisa waxaa laga dhigay: $newStatus')),
      );

      // Refresh local selection details
      if (_selectedOrder != null && _selectedOrder!['id'] == orderId) {
        setState(() {
          _selectedOrder!['status'] = newStatus;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cillad ayaa dhacday: $e')),
      );
    }
  }

  Future<void> _dispatchOrderWithCourier(String orderId) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text("Macluumaadka Darawalka"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Fadlan geli magaca iyo taleefanka wiilka mootada u wada dalabkaan (waa doorasho/optional).",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Magaca Darawalka",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Taleefanka Darawalka",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ka Laabo", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final riderName = nameController.text.trim();
                final riderPhone = phoneController.text.trim();
                Navigator.pop(context);

                try {
                  await Supabase.instance.client
                      .from('orders')
                      .update({
                        'status': 'On The Way',
                        'rider_name': riderName.isEmpty ? null : riderName,
                        'rider_phone': riderPhone.isEmpty ? null : riderPhone,
                      })
                      .eq('id', orderId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dalabka waa loo diray jidka (On The Way)!')),
                  );

                  // Update selection locally
                  if (_selectedOrder != null && _selectedOrder!['id'] == orderId) {
                    setState(() {
                      _selectedOrder!['status'] = 'On The Way';
                      _selectedOrder!['rider_name'] = riderName.isEmpty ? null : riderName;
                      _selectedOrder!['rider_phone'] = riderPhone.isEmpty ? null : riderPhone;
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cillad ayaa dhacday: $e')),
                  );
                }
              },
              child: const Text("U Dir Jidka"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 280,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delivery_dining, color: Colors.teal, size: 28),
              ),
              const SizedBox(width: 12),
              const Text(
                "Staff Panel",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildSidebarFilterItem('All', Icons.all_inbox, "Dhammaan orders-ka", isDrawer: isDrawer),
          _buildSidebarFilterItem('Pending', Icons.hourglass_empty, "Cusub (Pending)", isDrawer: isDrawer),
          _buildSidebarFilterItem('Accepted', Icons.check_circle_outline, "La aqbalay", isDrawer: isDrawer),
          _buildSidebarFilterItem('Cooking', Icons.restaurant, "Karinta (Cooking)", isDrawer: isDrawer),
          _buildSidebarFilterItem('On The Way', Icons.local_shipping_outlined, "Jidka ku jira", isDrawer: isDrawer),
          _buildSidebarFilterItem('Arrived', Icons.home_outlined, "Gaaray", isDrawer: isDrawer),
          _buildSidebarFilterItem('Cancelled', Icons.cancel_outlined, "La joojiyay", isDrawer: isDrawer),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Kabax App-ka", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFilterItem(String status, IconData icon, String title, {bool isDrawer = false}) {
    final isSelected = _selectedStatusFilter == status;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatusFilter = status;
          _selectedOrder = null; // Clear selection when filter changes
          _selectedOrderItems = null;
        });
        if (isDrawer) {
          Navigator.pop(context); // Close drawer
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.teal : Colors.grey.shade600),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.teal : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'Cooking':
        return Colors.purple;
      case 'On The Way':
        return Colors.indigo;
      case 'Arrived':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    // Filter locally based on selected tab
    final filtered = orders.where((order) {
      if (_selectedStatusFilter == 'All') return true;
      return (order['status'] as String? ?? 'Pending').toLowerCase() ==
          _selectedStatusFilter.toLowerCase();
    }).toList();

    // Check for new orders to trigger sound
    if (orders.isNotEmpty) {
      final newIds = orders.map((o) => o['id'].toString()).toList();
      bool hasNew = false;
      for (final id in newIds) {
        if (!_previousOrderIds.contains(id)) {
          hasNew = true;
          _previousOrderIds.add(id);
        }
      }
      if (hasNew && _previousOrderIds.length > newIds.length) {
        // Trigger sound only on subsequent additions, not initial load
        WidgetsBinding.instance.addPostFrameCallback((_) => _playNewOrderSound());
      }
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Ma jiraan dalabaad hadda ku jira qaybta $_selectedStatusFilter.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text("Dalab #")),
              DataColumn(label: Text("Macmiilka")),
              DataColumn(label: Text("Degmada")),
              DataColumn(label: Text("Payment")),
              DataColumn(label: Text("Lacagta")),
              DataColumn(label: Text("Xaalada (Status)")),
              DataColumn(label: Text("Waqtiga")),
            ],
            rows: filtered.map((order) {
              final shortId = order['id'].toString().substring(0, 5).toUpperCase();
              final name = order['customer_name'] ?? 'N/A';
              final district = order['district'] ?? 'N/A';
              final payment = order['delivery_details'] ?? 'Cash';
              final total = order['total_amount'] ?? 0.0;
              final status = order['status'] ?? 'Pending';
              final timeStr = order['created_at'] != null
                  ? DateFormat('hh:mm a').format(DateTime.parse(order['created_at']))
                  : 'N/A';

              final isSelected = _selectedOrder != null && _selectedOrder!['id'] == order['id'];

              return DataRow(
                selected: isSelected,
                onSelectChanged: (val) {
                  setState(() {
                    _selectedOrder = order;
                  });
                  _fetchOrderItems(order['id']);
                },
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("#ORD-$shortId", style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (status == 'Pending') ...[
                          const SizedBox(width: 8),
                          const _BlinkingNewDot(),
                        ],
                      ],
                    ),
                  ),
                  DataCell(Text(name)),
                  DataCell(Text(district)),
                  DataCell(Text(payment.toString().contains('EVC') ? 'EVC Plus' : 'Cash')),
                  DataCell(Text('\$${double.parse(total.toString()).toStringAsFixed(2)}')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(timeStr)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSidebar({bool isCollapsible = false}) {
    if (_selectedOrder == null) {
      if (isCollapsible) return const SizedBox.shrink();
      return Container(
        width: 420,
        color: Colors.white,
        child: const Center(
          child: Text(
            "Dooro dalab si aad u aragto faahfaahintiisa",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final order = _selectedOrder!;
    final shortId = order['id'].toString().substring(0, 5).toUpperCase();
    final name = order['customer_name'] ?? 'N/A';
    final phone = order['customer_phone'] ?? 'N/A';
    final city = order['city'] ?? 'Mogadishu';
    final district = order['district'] ?? 'N/A';
    final details = order['delivery_details'] ?? 'N/A';
    final subtotal = double.parse((order['subtotal'] ?? 0).toString());
    final fee = double.parse((order['delivery_fee'] ?? 0).toString());
    final total = double.parse((order['total_amount'] ?? 0).toString());
    final status = order['status'] ?? 'Pending';

    return Container(
      width: isCollapsible ? double.infinity : 420,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isCollapsible) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setState(() {
                          _selectedOrder = null;
                          _selectedOrderItems = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      "Dalab #ORD-$shortId",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (!isCollapsible)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectedOrder = null;
                      _selectedOrderItems = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text("MACMIILKA & LOCATION-KA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(phone),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text("$district, $city"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text("Fariin/Details: $details")),
              ],
            ),
            if (order['rider_name'] != null && order['rider_name'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.delivery_dining, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Darawalka: ${order['rider_name']} (${order['rider_phone'] ?? 'N/A'})",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text("CUNTOOYINKA LA DALBADAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            if (_isLoadingItems)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
            else if (_selectedOrderItems == null || _selectedOrderItems!.isEmpty)
              const Text("Lama helin wax cuntooyin ah oo dalabkaan ka tirsan.", style: TextStyle(color: Colors.grey))
            else
              ..._selectedOrderItems!.map((item) {
                final itemName = item['item_name'] ?? 'N/A';
                final qty = item['quantity'] ?? 1;
                final price = double.parse((item['price'] ?? 0.0).toString());
                final totalItemPrice = price * qty;
                final imagePath = item['image_path'] as String?;
                final isNetwork = (imagePath ?? '').startsWith('http');

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imagePath != null
                            ? (isNetwork
                                ? Image.network(
                                    imagePath,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey.shade100,
                                      child: const Icon(Icons.restaurant, size: 20, color: Colors.grey),
                                    ),
                                  )
                                : Image.asset(
                                    'assets/$imagePath',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey.shade100,
                                      child: const Icon(Icons.restaurant, size: 20, color: Colors.grey),
                                    ),
                                  ))
                            : Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.restaurant, size: 20, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "x$qty",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "\$${totalItemPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text("SUMMARY-GA LACAGTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal:"),
                Text("\$${subtotal.toStringAsFixed(2)}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Delivery Fee:"),
                Text("\$${fee.toStringAsFixed(2)}"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Amount:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 12),
            const Text("STATUS ACTIONS (BEDEL)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            if (status == 'Pending') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order['id'], 'Accepted'),
                  icon: const Icon(Icons.check),
                  label: const Text("Accept Order (Aqbal)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ] else if (status == 'Accepted') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order['id'], 'Cooking'),
                  icon: const Icon(Icons.restaurant),
                  label: const Text("Start Cooking (Bilow karinta)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ] else if (status == 'Cooking') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _dispatchOrderWithCourier(order['id']),
                  icon: const Icon(Icons.local_shipping),
                  label: const Text("Send Courier (U dir jidka)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ] else if (status == 'On The Way') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order['id'], 'Arrived'),
                  icon: const Icon(Icons.home),
                  label: const Text("Mark Arrived (Gaaray)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (status != 'Arrived' && status != 'Cancelled') ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _updateOrderStatus(order['id'], 'Cancelled'),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text("Cancel Order (Jooji)", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = screenWidth >= 1100;
    final showDetailsAsSidebar = screenWidth >= 850;

    Widget mainContent = Padding(
      padding: EdgeInsets.all(screenWidth < 600 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!showSidebar) ...[
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Staff Order Panel (Real-time)",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Hadda waxaad daawanaysaa: $_selectedStatusFilter orders",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi, size: 14, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      "Live Connected",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth < 600 ? 16 : 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: _isLoadingOrders
                  ? const Center(child: CircularProgressIndicator())
                  : _buildOrdersList(_orders),
            ),
          ),
        ],
      ),
    );

    // If screen is narrow and an order is selected, show details page instead of table
    final showDetailsScreen = !showDetailsAsSidebar && _selectedOrder != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      drawer: !showSidebar ? Drawer(child: _buildSidebar(isDrawer: true)) : null,
      body: Row(
        children: [
          if (showSidebar) ...[
            _buildSidebar(isDrawer: false),
            const VerticalDivider(width: 1),
          ],
          if (!showDetailsScreen)
            Expanded(child: mainContent),
          if (_selectedOrder != null) ...[
            if (showDetailsAsSidebar) ...[
              const VerticalDivider(width: 1),
              _buildOrderDetailsSidebar(isCollapsible: false),
            ] else if (showDetailsScreen) ...[
              Expanded(child: _buildOrderDetailsSidebar(isCollapsible: true)),
            ]
          ],
        ],
      ),
    );
  }
}

// Widget-ka Sameynaya blinking/flashing dot-ka cas ee u gaarka ah Dalabka Cusub
class _BlinkingNewDot extends StatefulWidget {
  const _BlinkingNewDot();

  @override
  State<_BlinkingNewDot> createState() => _BlinkingNewDotState();
}

class _BlinkingNewDotState extends State<_BlinkingNewDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_new, color: Colors.white, size: 14),
            SizedBox(width: 2),
            Text(
              "Cusub",
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
