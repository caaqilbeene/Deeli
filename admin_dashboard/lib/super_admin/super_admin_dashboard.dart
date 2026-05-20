import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../auth/login_page.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedTabIndex = 0; // 0: Dashboard, 1: Food Management, 2: Settings
  final List<Map<String, dynamic>> _menuItems = [];
  bool _isLoadingMenu = false;

  int _todayOrdersCount = 0;
  double _todayEarnings = 0.0;
  int _totalUsersCount = 0;
  int _totalOrdersCount = 0;
  List<Map<String, dynamic>> _topSellingItems = [];
  List<double> _weeklyEarnings = [0, 0, 0, 0, 0, 0, 0];

  // Food Form Controllers
  final _foodFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();

  Map<String, dynamic>? _selectedItemToEdit;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
    _fetchDashboardStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenuItems() async {
    setState(() => _isLoadingMenu = true);
    try {
      final response = await Supabase.instance.client
          .from('menu_items')
          .select()
          .order('name');
      setState(() {
        _menuItems.clear();
        _menuItems.addAll(List<Map<String, dynamic>>.from(response));
        _isLoadingMenu = false;
      });
    } catch (e) {
      setState(() => _isLoadingMenu = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading menu items: $e')),
      );
    }
  }

  Future<void> _fetchDashboardStats() async {
    if (!mounted) return;
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch all orders
      final ordersRes = await supabase.from('orders').select();
      final allOrders = List<Map<String, dynamic>>.from(ordersRes);

      // 2. Fetch all order items
      final orderItemsRes = await supabase.from('order_items').select();
      final allOrderItems = List<Map<String, dynamic>>.from(orderItemsRes);

      // 3. Fetch users count
      final usersRes = await supabase.from('users').select('id');
      final usersCount = usersRes.length;

      // Calculate stats
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      
      int todayOrders = 0;
      double todayRevenue = 0.0;
      List<double> weeklyRev = [0, 0, 0, 0, 0, 0, 0];

      // Current week start (Monday)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);

      for (var order in allOrders) {
        final createdAtStr = order['created_at'] as String?;
        if (createdAtStr == null) continue;
        final createdAt = DateTime.parse(createdAtStr).toLocal();
        final totalAmount = double.tryParse((order['total_amount'] ?? 0.0).toString()) ?? 0.0;
        final status = order['status'] ?? 'Pending';

        if (status == 'Cancelled') continue;

        // Today's orders & revenue
        if (createdAt.isAfter(startOfToday)) {
          todayOrders++;
          todayRevenue += totalAmount;
        }

        // Weekly revenue (Mon-Sun)
        if (createdAt.isAfter(startOfWeek)) {
          final dayIdx = createdAt.weekday - 1;
          if (dayIdx >= 0 && dayIdx < 7) {
            weeklyRev[dayIdx] += totalAmount;
          }
        }
      }

      // Calculate top selling items
      final Map<String, int> itemSales = {};
      for (var item in allOrderItems) {
        final name = item['item_name'] ?? 'N/A';
        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
        itemSales[name] = (itemSales[name] ?? 0) + qty;
      }

      final sortedSales = itemSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topFoods = sortedSales.take(4).map((entry) {
        return {
          'name': entry.key,
          'count': entry.value,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _todayOrdersCount = todayOrders;
          _todayEarnings = todayRevenue;
          _totalUsersCount = usersCount;
          _totalOrdersCount = allOrders.length;
          _weeklyEarnings = weeklyRev;
          _topSellingItems = topFoods;
        });
      }
    } catch (e) {
    }
  }

  Future<void> _addOrUpdateMenuItem() async {
    if (!_foodFormKey.currentState!.validate()) return;

    final itemData = {
      'name': _nameController.text.trim(),
      'price': double.parse(_priceController.text),
      'category': _categoryController.text.trim(),
      'description': _descriptionController.text.trim(),
      'image_path': _imageController.text.trim().isEmpty
          ? 'images/burgerfal.jpeg'
          : _imageController.text.trim(),
      'kcal': _kcalController.text.trim(),
      'protein': _proteinController.text.trim(),
      'fats': _fatsController.text.trim(),
      'carbs': _carbsController.text.trim(),
    };

    try {
      if (_selectedItemToEdit == null) {
        // Insert
        await Supabase.instance.client.from('menu_items').insert(itemData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cunto cusub waa la soo galiyay!')),
        );
      } else {
        // Update
        await Supabase.instance.client
            .from('menu_items')
            .update(itemData)
            .eq('id', _selectedItemToEdit!['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuntada waa la cusbooneysiiyay!')),
        );
      }
      Navigator.pop(context);
      _clearForm();
      _fetchMenuItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cillad ayaa dhacday: $e')),
      );
    }
  }

  Future<void> _deleteMenuItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tirtir Cuntada"),
        content: const Text("Ma hubtaa inaad tirtirto cuntadan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Ka laabo"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Tirtir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('menu_items').delete().eq('id', id);
        _fetchMenuItems();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuntadii waa la tirtiray!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wuu diiday inuu tirtiro: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _imageController.clear();
    _kcalController.clear();
    _proteinController.clear();
    _fatsController.clear();
    _carbsController.clear();
    _selectedItemToEdit = null;
  }

  void _openFoodModal({Map<String, dynamic>? item}) {
    if (item != null) {
      _selectedItemToEdit = item;
      _nameController.text = (item['name'] ?? '').toString();
      _priceController.text = (item['price'] ?? '').toString();
      _categoryController.text = (item['category'] ?? '').toString();
      _descriptionController.text = (item['description'] ?? '').toString();
      _imageController.text = (item['image_path'] ?? '').toString();
      _kcalController.text = (item['kcal'] ?? '').toString();
      _proteinController.text = (item['protein'] ?? '').toString();
      _fatsController.text = (item['fats'] ?? '').toString();
      _carbsController.text = (item['carbs'] ?? '').toString();
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Form(
              key: _foodFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item == null ? "Soo gali Cunto Cusub" : "Cusbooneysii Cuntada",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Magaca Cuntada",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Geli magaca" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Qiimaha (USD)",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              double.tryParse(v ?? '') == null ? "Qiimo sax ah geli" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: "Category (Meals, Shawarma, Drinks, Fries)",
                            border: OutlineInputBorder(),
                            hintText: "Meals",
                          ),
                          validator: (v) => v!.isEmpty ? "Geli category" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _imageController,
                          decoration: const InputDecoration(
                            labelText: "Sawirka (URL ama Asset path)",
                            border: OutlineInputBorder(),
                            hintText: "https://images.unsplash.com/...",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Faahfaahinta Cuntada / Description",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Geli faahfaahin" : null,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Nutrition Info (Nafaqada - Optional)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _kcalController,
                          decoration: const InputDecoration(
                            labelText: "Kcal",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _proteinController,
                          decoration: const InputDecoration(
                            labelText: "Protein",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _fatsController,
                          decoration: const InputDecoration(
                            labelText: "Fats",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _carbsController,
                          decoration: const InputDecoration(
                            labelText: "Carbs",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _addOrUpdateMenuItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        item == null ? "Save Cunto" : "Cusbooneysii Cuntada",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                  color: Colors.deepOrange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu, color: Colors.deepOrange, size: 28),
              ),
              const SizedBox(width: 12),
              const Text(
                "Al Raxma",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildSidebarItem(0, Icons.dashboard_outlined, "Dashboard", isDrawer: isDrawer),
          _buildSidebarItem(1, Icons.restaurant_outlined, "Food Management", isDrawer: isDrawer),
          _buildSidebarItem(2, Icons.settings_outlined, "Settings", isDrawer: isDrawer),
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

  Widget _buildSidebarItem(int index, IconData icon, String title, {bool isDrawer = false}) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        if (isDrawer) {
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.deepOrange : Colors.grey.shade600),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = screenWidth >= 1100;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth < 600 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Super Admin Dashboard",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text("Xogta guud, dakhliga, iyo tirakoobka app-ka"),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMMM, yyyy').format(DateTime.now())),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Stats Grid/Wrap
          GridView.count(
            crossAxisCount: screenWidth < 600 ? 1 : (screenWidth < 1300 ? 2 : 4),
            childAspectRatio: screenWidth < 600 ? 2.2 : (screenWidth < 1300 ? 1.8 : 1.6),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                "Dalabada Maanta",
                "$_todayOrdersCount",
                "Dalab maanta la diray",
                Icons.shopping_bag_outlined,
                Colors.blue,
              ),
              _buildStatCard(
                "Dakhliga Maanta",
                "\$${_todayEarnings.toStringAsFixed(2)}",
                "USD",
                Icons.attach_money,
                Colors.green,
              ),
              _buildStatCard(
                "Macaamiisha Guud",
                "$_totalUsersCount",
                "Macaamiil is-diiwaangeliyay",
                Icons.people_outline,
                Colors.orange,
              ),
              _buildStatCard(
                "Dalabaadka Guud",
                "$_totalOrdersCount",
                "Dalab oo dhan",
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Charts Section
          if (screenWidth >= 950)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRevenueChart(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildTopSellingFoods(),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildRevenueChart(),
                const SizedBox(height: 24),
                _buildTopSellingFoods(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dakhliga Toddobaadkan (\$)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _weeklyEarnings.reduce((a, b) => a > b ? a : b) > 100
                    ? _weeklyEarnings.reduce((a, b) => a > b ? a : b) + 50
                    : 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Isn', 'Tal', 'Arb', 'Kha', 'Jim', 'Sab', 'Axa'];
                        return Text(days[value.toInt() % 7]);
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarGroup(0, _weeklyEarnings[0]),
                  _makeBarGroup(1, _weeklyEarnings[1]),
                  _makeBarGroup(2, _weeklyEarnings[2]),
                  _makeBarGroup(3, _weeklyEarnings[3]),
                  _makeBarGroup(4, _weeklyEarnings[4]),
                  _makeBarGroup(5, _weeklyEarnings[5]),
                  _makeBarGroup(6, _weeklyEarnings[6]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingFoods() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cuntooyinka ugu iibka badan",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (_topSellingItems.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "Lama hayo wax dalabaad ah weli.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: _topSellingItems.map((item) {
                  final name = item['name'] as String;
                  final count = item['count'] as int;
                  final maxCount = _topSellingItems.first['count'] as int;
                  final double percent = maxCount > 0 ? (count / maxCount) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _TopFoodItemRow(
                      name: name,
                      orders: "$count dalab",
                      percentage: percent,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.deepOrange,
          width: 22,
          borderRadius: BorderRadius.circular(4),
        )
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodManagementView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = screenWidth >= 1100;

    return Padding(
      padding: EdgeInsets.all(screenWidth < 600 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Food Management (Menu)",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text("Kudar, badal ama tirtir cuntooyinka iyo cabitaanada"),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openFoodModal(),
                      icon: const Icon(Icons.add),
                      label: const Text("Cunto Cusub"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
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
              child: _isLoadingMenu
                  ? const Center(child: CircularProgressIndicator())
                  : _menuItems.isEmpty
                      ? const Center(child: Text("Ma jiraan cuntooyin hadda ku jira database-ka."))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                              headingRowColor:
                                  MaterialStateProperty.all(Colors.grey.shade50),
                              columns: const [
                                DataColumn(label: Text("Sawirka")),
                                DataColumn(label: Text("Magaca")),
                                DataColumn(label: Text("Category")),
                                DataColumn(label: Text("Qiimaha")),
                                DataColumn(label: Text("Calories")),
                                DataColumn(label: Text("Wax Ka Bedel")),
                              ],
                              rows: _menuItems.map((item) {
                                final isNetwork =
                                    (item['image_path'] ?? '').startsWith('http');
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: isNetwork
                                            ? Image.network(
                                                item['image_path'],
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    Container(color: Colors.grey.shade200, width: 48, height: 48, child: const Icon(Icons.broken_image)),
                                              )
                                            : Image.asset(
                                                'assets/${item['image_path']}',
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    Container(color: Colors.grey.shade200, width: 48, height: 48, child: const Icon(Icons.restaurant)),
                                              ),
                                      ),
                                    ),
                                    DataCell(Text(
                                      item['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    )),
                                    DataCell(Text(item['category'] ?? '')),
                                    DataCell(Text('\$${(item['price'] ?? 0.0).toStringAsFixed(2)}')),
                                    DataCell(Text('${item['kcal'] ?? 'N/A'} Kcal')),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _openFoodModal(item: item),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteMenuItem(item['id']),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = screenWidth >= 1100;

    return Padding(
      padding: EdgeInsets.all(screenWidth < 600 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  children: const [
                    Text(
                      "Settings",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text("Habeey guud ahaan goobaha restaurant-ka iyo lacagta geynta"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Restaurant Settings",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.deepOrange),
                  title: const Text("Mogadishu Head Office"),
                  subtitle: const Text("Howlwadaag, Mogadishu, Somalia"),
                  trailing: TextButton(onPressed: () {}, child: const Text("Badal")),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delivery_dining, color: Colors.deepOrange),
                  title: const Text("Delivery Configuration"),
                  subtitle: const Text("Dhammaan lacagta geynta ee degmooyinka hadda waa \$0.00"),
                  trailing: TextButton(onPressed: () {}, child: const Text("Maamul")),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.deepOrange),
                  title: const Text("System Notifications"),
                  subtitle: const Text("U dir fariimo realtime ah dhammaan macaamiisha iyo shaqaalaha"),
                  trailing: TextButton(onPressed: () {}, child: const Text("Maamul")),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = screenWidth >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      drawer: !showSidebar ? Drawer(child: _buildSidebar(isDrawer: true)) : null,
      body: Row(
        children: [
          if (showSidebar) ...[
            _buildSidebar(isDrawer: false),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildDashboardView(),
                _buildFoodManagementView(),
                _buildSettingsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopFoodItemRow extends StatelessWidget {
  final String name;
  final String orders;
  final double percentage;

  const _TopFoodItemRow({
    required this.name,
    required this.orders,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(orders, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation(Colors.deepOrange),
          ),
        ),
      ],
    );
  }
}
