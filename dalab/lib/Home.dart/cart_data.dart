class CartItem {
  String name;
  String image;
  double price;
  int quantity;

  CartItem({
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });
}

class CartData {
  static List<CartItem> items = [];

  static int get cartCount {
    int total = 0;
    for (var item in items) {
      total = total + item.quantity;
    }
    return total;
  }

  static double get subtotal {
    double total = 0;
    for (var item in items) {
      total = total + (item.price * item.quantity);
    }
    return total;
  }

  static void addToCart({
    required String name,
    required String image,
    required double price,
    required int quantity,
  }) {
    // items.add(
    //   CartItem(name: name, image: image, price: price, quantity: quantity),
    // );
    final existingIndex = items.indexWhere((item) => item.name == name);

    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(
        CartItem(name: name, image: image, price: price, quantity: quantity),
      );
    }
  }

  static void clearCart() {
    items.clear();
  }

  // ✅ cart_data.dart - method cusub ku dar
  static void removeOneFromCart(String name) {
    final index = items.indexWhere((item) => item.name == name);
    if (index >= 0) {
      if (items[index].quantity > 1) {
        items[index].quantity--;
      } else {
        items.removeAt(index);
      }
    }
  }
}
