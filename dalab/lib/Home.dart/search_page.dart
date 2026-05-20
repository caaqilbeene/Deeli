import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dalab/models/menu_item.dart';
import 'package:dalab/Home.dart/widgets/menu_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dalab/Home.dart/cart_data.dart';
import 'package:dalab/Home.dart/cart_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = "";
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Auto-focus search bar when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  List<MenuItem> getFilteredItems(List<MenuItem> items) {
    if (searchQuery.isEmpty) return []; // Show nothing until typed
    return items.where((item) {
      return item.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  int get cartCount => CartData.cartCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.chevron_back, color: Colors.black),
        ),
        title: TextField(
          focusNode: _focusNode,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: "Search food, drink, etc...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                    setState(() {});
                  },
                  icon: const Icon(CupertinoIcons.shopping_cart, color: Colors.black),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('menu_items').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Cillad: ${snapshot.error}'));
                }

                final data = snapshot.data ?? [];
                final allItems = data.map((map) {
                  final item = MenuItem.fromMap(map);
                  item.updateQuantityFromCart();
                  return item;
                }).toList();

                final filteredItems = getFilteredItems(allItems);

                if (searchQuery.isNotEmpty && filteredItems.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items found",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                if (searchQuery.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.search, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "Type to search for food",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) => _buildItem(filteredItems[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MenuImage(
              imagePath: item.imagePath,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (item.subtitle.isNotEmpty)
                  Text(
                    item.subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                const SizedBox(height: 8),
                Text(
                  "\$${item.price.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                CartData.addToCart(
                  name: item.name,
                  image: item.imagePath,
                  price: item.price,
                  quantity: 1,
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${item.name} added to cart", style: TextStyle(color: Colors.white)), backgroundColor: Colors.deepOrange, duration: Duration(seconds: 1)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 0),
            ),
            child: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
