import 'package:dalab/Home.dart/cart_data.dart';

class MenuItem {
  final String id;
  final String name;
  final String subtitle;
  final String imagePath;
  final double price;
  final String category;
  final String description;
  final String kcal;
  final String protein;
  final String fats;
  final String carbs;
  final String deliveryTime;
  final double rating;
  int quantity;

  MenuItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imagePath,
    required this.price,
    required this.category,
    this.description = '',
    this.kcal = '',
    this.protein = '',
    this.fats = '',
    this.carbs = '',
    this.deliveryTime = '',
    this.rating = 4.5,
    this.quantity = 0,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as String,
      name: map['name'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      imagePath: map['image_path'] as String,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
      description: map['description'] as String? ?? '',
      kcal: map['kcal'] as String? ?? '',
      protein: map['protein'] as String? ?? '',
      fats: map['fats'] as String? ?? '',
      carbs: map['carbs'] as String? ?? '',
      deliveryTime: map['delivery_time'] as String? ?? '',
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : 4.5,
    );
  }

  double get totalPrice => quantity * price;

  void updateQuantityFromCart() {
    // Helper to sync quantity with global cart
    final cartItem = CartData.items.firstWhere(
      (item) => item.name == name,
      orElse: () => CartItem(name: name, image: imagePath, price: price, quantity: 0),
    );
    quantity = cartItem.quantity;
  }
}
