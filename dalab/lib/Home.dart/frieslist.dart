import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dalab/Home.dart/cart_data.dart';
import 'package:dalab/Home.dart/cart_page.dart';
import 'package:dalab/models/menu_item.dart';
import 'package:dalab/Home.dart/widgets/menu_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Frieslist extends StatefulWidget {
  const Frieslist({super.key});

  @override
  State<Frieslist> createState() => _FrieslistState();
}

class _FrieslistState extends State<Frieslist> {
  String searchQuery = "";
  final SupabaseClient _supabase = Supabase.instance.client;

  List<MenuItem> getFilteredItems(List<MenuItem> items) {
    if (searchQuery.isEmpty) return items;
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
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.chevron_back),
        ),
        title: const Text(
          "Fries",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                    setState(() {});
                  },
                  icon: const Icon(CupertinoIcons.shopping_cart),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search fries...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('menu_items')
                  .stream(primaryKey: ['id'])
                  .eq('category', 'Fries'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }
                
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Lama xiriiri karo server-ka. Fadlan hubi internet-kaaga.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  );
                }
                
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items found",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Map to model and sync quantities
                final items = data.map((map) {
                  final item = MenuItem.fromMap(map);
                  item.updateQuantityFromCart();
                  return item;
                }).toList();
                
                final filtered = getFilteredItems(items);
                
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      "No matching items",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildItem(filtered[index]),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (item.quantity > 0) {
                      item.quantity--;
                      CartData.removeOneFromCart(item.name);
                    }
                  });
                },
                icon: const Icon(Icons.remove, size: 20),
              ),
              Text(
                item.quantity == 0
                    ? "\$${item.price.toStringAsFixed(2)}"
                    : "\$${item.totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    item.quantity++;
                    CartData.addToCart(
                      name: item.name,
                      image: item.imagePath,
                      price: item.price,
                      quantity: 1,
                    );
                  });
                },
                icon: const Icon(Icons.add, size: 20, color: Colors.deepOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
