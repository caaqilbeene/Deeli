import 'package:dalab/Home.dart/cart_page.dart';
import 'package:dalab/Home.dart/widgets/nutrition_box.dart';
import 'package:dalab/models/menu_item.dart';
import 'package:dalab/Home.dart/widgets/menu_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dalab/Home.dart/cart_data.dart';

class ItemDetailsPage extends StatefulWidget {
  final MenuItem item;
  
  const ItemDetailsPage({super.key, required this.item});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  int quantity = 1;
  double get totalprice => quantity * widget.item.price;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          MenuImage(
            imagePath: widget.item.imagePath,
            height: MediaQuery.of(context).size.height / 2,
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(50),
              ),
              margin: const EdgeInsets.only(top: 40, left: 20),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
                setState(() {});
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      CupertinoIcons.shopping_cart,
                      color: Colors.black,
                    ),
                  ),
                  if (CartData.cartCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${CartData.cartCount}",
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
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.58,
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "\$${totalprice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          "Rate",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.star_half, color: Colors.deepOrange),
                        const SizedBox(width: 5),
                        Text(
                          widget.item.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (widget.item.deliveryTime.isNotEmpty)
                          Row(
                            children: [
                              const Icon(CupertinoIcons.time),
                              const SizedBox(width: 5),
                              Text(
                                widget.item.deliveryTime,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.item.kcal.isNotEmpty || widget.item.protein.isNotEmpty) ...[
                      const Text(
                        "Nutrition Facts",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.item.kcal.isNotEmpty) nutriBox("Kcal", widget.item.kcal),
                          if (widget.item.protein.isNotEmpty) nutriBox("Protein", widget.item.protein),
                          if (widget.item.fats.isNotEmpty) nutriBox("Fats", widget.item.fats),
                          if (widget.item.carbs.isNotEmpty) nutriBox("Carbs", widget.item.carbs),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.item.description.isNotEmpty) ...[
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.item.description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      "Quantity",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (quantity > 1) {
                                        quantity--;
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.remove),
                                ),
                                Text("Qty: $quantity"),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      quantity++;
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                CartData.addToCart(
                                  name: widget.item.name,
                                  image: widget.item.imagePath,
                                  price: widget.item.price,
                                  quantity: quantity,
                                );
                                quantity = 1;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${widget.item.name} added to cart",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.deepOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.shopping_cart,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Add to cart",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
