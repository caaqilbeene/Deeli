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
  int _selectedTabIndex = 0; // 0: Dashboard, 1: Food Management, 2: Loyalty Cards, 3: Settings
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
  final _deliveryTimeController = TextEditingController();
  final _discountController = TextEditingController();

  Map<String, dynamic>? _selectedItemToEdit;

  // Super Admin Loyalty Cards & Bonuses Variables
  final _searchCardController = TextEditingController();
  final _deductAmountController = TextEditingController();
  final _newCardCodeController = TextEditingController();

  Map<String, dynamic>? _searchedCardData;
  String? _searchedCardOwner;
  bool _isSearchingCard = false;
  bool _isDeductingCard = false;
  bool _isAddingCard = false;
  String? _cardSearchError;
  String? _cardAddError;

  List<Map<String, dynamic>> _topLoyaltyCustomers = [];
  bool _isLoadingTopLoyalty = false;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
    _fetchDashboardStats();
    _fetchTopLoyaltyCustomers();
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
    _deliveryTimeController.dispose();
    _discountController.dispose();

    _searchCardController.dispose();
    _deductAmountController.dispose();
    _newCardCodeController.dispose();
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

  Future<void> _fetchTopLoyaltyCustomers() async {
    setState(() => _isLoadingTopLoyalty = true);
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('users')
          .select('name, bonus_balance, phone')
          .order('bonus_balance', ascending: false)
          .limit(10);
      setState(() {
        _topLoyaltyCustomers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching top loyalty customers: $e");
    } finally {
      setState(() => _isLoadingTopLoyalty = false);
    }
  }

  Future<void> _searchCardDetails() async {
    final String codeToSearch = _searchCardController.text.trim().toUpperCase();
    if (codeToSearch.length != 4) {
      setState(() {
        _cardSearchError = "Fadlan geli nambar 4 xaraf ah!";
        _searchedCardData = null;
        _searchedCardOwner = null;
      });
      return;
    }

    setState(() {
      _isSearchingCard = true;
      _cardSearchError = null;
      _searchedCardData = null;
      _searchedCardOwner = null;
    });

    try {
      final cardRes = await Supabase.instance.client
          .from('physical_cards')
          .select('card_number, status, balance, linked_user_id')
          .eq('card_number', codeToSearch)
          .maybeSingle();

      if (cardRes == null) {
        setState(() {
          _cardSearchError = "Nambarka kaarkaan kuma jiro diiwaanka!";
        });
        return;
      }

      setState(() {
        _searchedCardData = Map<String, dynamic>.from(cardRes);
      });

      final String? ownerId = cardRes['linked_user_id'];
      if (ownerId != null) {
        final userRes = await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', ownerId)
            .maybeSingle();
        if (userRes != null && userRes['name'] != null) {
          setState(() {
            _searchedCardOwner = userRes['name'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _cardSearchError = "Cillad ayaa dhacday intii baaritaanku socday.";
      });
    } finally {
      setState(() {
        _isSearchingCard = false;
      });
    }
  }

  Future<void> _deductCardBalance() async {
    final double? amount = double.tryParse(_deductAmountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fadlan geli lacag sax ah oo eber ka weyn!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final double currentBal = ((_searchedCardData!['balance'] ?? 0.0) as num).toDouble();
    if (amount > currentBal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digniin: Lacagta ku jirta kaarka ayaa ka yar inta aad jarayso!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isDeductingCard = true;
    });

    try {
      final double newBal = currentBal - amount;
      await Supabase.instance.client
          .from('physical_cards')
          .update({'balance': newBal})
          .eq('card_number', _searchedCardData!['card_number']);

      setState(() {
        _searchedCardData!['balance'] = newBal;
        _deductAmountController.clear();
      });

      // Reload leaderboard
      await _fetchTopLoyaltyCustomers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Si guul leh ayaa looga jaray ${amount.toStringAsFixed(2)} kaarka!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cillad ayaa dhacday intii lacagta laga jarayay kaarka."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isDeductingCard = false;
      });
    }
  }

  Future<void> _registerNewPhysicalCard() async {
    final String code = _newCardCodeController.text.trim().toUpperCase();

    if (code.length != 4) {
      setState(() {
        _cardAddError = "Nambarka kaarku waa inuu ahaadaa 4 xaraf/nambar!";
      });
      return;
    }
    final firstChar = code.substring(0, 1);
    if (!RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
      setState(() {
        _cardAddError = "Koodhka waa inuu ku bilaabmo xaraf (Tusaale: D101)!";
      });
      return;
    }

    setState(() {
      _isAddingCard = true;
      _cardAddError = null;
    });

    try {
      // Check if card code already exists
      final existing = await Supabase.instance.client
          .from('physical_cards')
          .select('card_number')
          .eq('card_number', code)
          .maybeSingle();

      if (existing != null) {
        setState(() {
          _cardAddError = "Koodhkan mar hore ayaa la diiwaangeliyay!";
        });
        return;
      }

      // Insert new card with 0.0 balance
      await Supabase.instance.client.from('physical_cards').insert({
        'card_number': code,
        'status': 'available',
        'balance': 0.0,
      });

      if (!mounted) return;
      _newCardCodeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kaarka physical-ka ah si guul leh ayaa loo diiwaangeliyay!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _cardAddError = "Cillad ayaa ka dhalatay diiwaangelinta database-ka.";
      });
    } finally {
      setState(() {
        _isAddingCard = false;
      });
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
      'delivery_time': _deliveryTimeController.text.trim(),
      'discount': int.tryParse(_discountController.text.trim()) ?? 0,
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
    _deliveryTimeController.clear();
    _discountController.clear();
    _selectedItemToEdit = null;
  }

  String _resolveAdminAssetPath(String path) {
    if (path.startsWith('assets/images/')) {
      return path;
    }
    if (path.startsWith('assets/')) {
      final rest = path.replaceFirst('assets/', '');
      if (rest.startsWith('images/')) {
        return 'assets/$rest';
      }
      return 'assets/images/$rest';
    }
    if (path.startsWith('images/')) {
      return 'assets/$path';
    }
    return 'assets/images/$path';
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
      _deliveryTimeController.text = (item['delivery_time'] ?? '').toString();
      _discountController.text = (item['discount'] ?? '0').toString();
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _deliveryTimeController,
                          decoration: const InputDecoration(
                            labelText: "Waqtiga Delivery-ga (Tusaale: 15-20 min)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Qiima Dhimista (%) (Tusaale: 20)",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final val = int.tryParse(v);
                              if (val == null || val < 0 || val > 100) {
                                return "Geli boqolley u dhaxaysa 0-100";
                              }
                            }
                            return null;
                          },
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
          _buildSidebarItem(2, Icons.credit_card_outlined, "Loyalty Cards", isDrawer: isDrawer),
          _buildSidebarItem(3, Icons.settings_outlined, "Settings", isDrawer: isDrawer),
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
                                                _resolveAdminAssetPath(item['image_path'] ?? ''),
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

  Widget _buildLoyaltyCardsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final showSidebar = screenWidth >= 1100;
    final isDesktop = screenWidth >= 900;

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CARD SEARCH LOOKUP
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                "Hubi Nambarka Kaarka (Card Lookup)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Geli 4-ta xaraf ee kaarka si aad u hubiso status-kiisa, balance-ka iyo qofka iska leh.",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCardController,
                      decoration: const InputDecoration(
                        hintText: "Geli 4 xaraf (Tusaale: D101)",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _searchCardDetails(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSearchingCard ? null : _searchCardDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSearchingCard
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Text("Hubi Kaarka"),
                    ),
                  ),
                ],
              ),
              if (_cardSearchError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _cardSearchError!,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
              if (_searchedCardData != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Kaarka: ${_searchedCardData!['card_number']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _searchedCardData!['status'] == 'active' ? Colors.green.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _searchedCardData!['status'].toString().toUpperCase(),
                              style: TextStyle(
                                color: _searchedCardData!['status'] == 'active' ? Colors.green : Colors.orange,
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
                          const Text("Lacagta ku jirta (Balance):", style: TextStyle(color: Colors.black54)),
                          Text(
                            ((_searchedCardData!['balance'] ?? 0.0) as num).toDouble().toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Qofka iska leh (Owner):", style: TextStyle(color: Colors.black54)),
                          Text(
                            _searchedCardOwner ?? "Lama xirin",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text(
                        "Lacag Ka Jar Kaarka (Deduct Balance)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _deductAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: "Geli lacagta laga jarayo (USD)",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _isDeductingCard ? null : _deductCardBalance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isDeductingCard
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                    )
                                  : const Text("Ka Jar"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. REGISTER NEW CARD
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                "Register New Physical Card",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Diiwaangeli kaar cusub adigoo gelinaya 4 xaraf (Tusaale: D101).",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _newCardCodeController,
                decoration: const InputDecoration(
                  hintText: "Code-ka Kaarka (Tusaale: D101)",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              if (_cardAddError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _cardAddError!,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isAddingCard ? null : _registerNewPhysicalCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isAddingCard
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          ),
                        )
                      : const Text("Diiwaangeli Kaarka Cusub", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    Widget rightColumn = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            "Macamiisha Ugu Dhibcaha Badan (Top Customers)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Liiska 10-ka macmiil ee ugu dhibcaha badan si loo gudoonsiiyo kaarka abaalmarinta.",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          if (_isLoadingTopLoyalty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.deepOrange)),
              ),
            )
          else if (_topLoyaltyCustomers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("Weli wax macaamiil ah lama helin.", style: TextStyle(color: Colors.black38)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topLoyaltyCustomers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = _topLoyaltyCustomers[index];
                final String name = customer['name'] ?? "Macmiil aan la aqoon";
                final double balance = (customer['bonus_balance'] as num?)?.toDouble() ?? 0.0;
                final String phone = customer['phone'] ?? "N/A";

                String rankPrefix = "${index + 1}. ";
                if (index == 0) rankPrefix = "🥇 ";
                if (index == 1) rankPrefix = "🥈 ";
                if (index == 2) rankPrefix = "🥉 ";

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepOrange.shade50,
                        child: Text(
                          rankPrefix.trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              phone,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        balance.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.all(screenWidth < 600 ? 16 : 32),
      child: SingleChildScrollView(
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
                        "Loyalty Cards & Bonuses",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text("Maamul kaararka physical-ka ah, baaritaanka, raadinta macaamiisha, iyo dhimista balance-ka"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: leftColumn),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: rightColumn),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftColumn,
                  const SizedBox(height: 24),
                  rightColumn,
                ],
              ),
          ],
        ),
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
                _buildLoyaltyCardsView(),
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
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
