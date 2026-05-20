import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dalab/Home.dart/cart_data.dart';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Save order to Supabase
  static Future<String?> saveOrder({
    required String name,
    required String phone,
    required String city,
    required String district,
    required String details,
    required double deliveryFee,
  }) async {
    try {
      // Create the order record
      final List<dynamic> orderResponse = await _supabase.from('orders').insert({
        'customer_name': name,
        'customer_phone': phone,
        'city': city,
        'district': district,
        'delivery_details': details,
        'subtotal': CartData.subtotal,
        'delivery_fee': deliveryFee,
        'total_amount': CartData.subtotal + deliveryFee,
        'status': 'Pending', // Changed to Pending as requested
      }).select();

      if (orderResponse.isNotEmpty) {
        final orderId = orderResponse.first['id'];

        // Prepare order items
        final List<Map<String, dynamic>> orderItems = CartData.items.map((item) {
          return {
            'order_id': orderId,
            'item_name': item.name,
            'quantity': item.quantity,
            'price': item.price,
          };
        }).toList();

        // Insert order items
        if (orderItems.isNotEmpty) {
          await _supabase.from('order_items').insert(orderItems);
        }
        return orderId.toString(); // Return the order ID on success
      }
      return 'Error: No response from database';
    } catch (e) {
      print('Error saving order to Supabase: $e');
      return 'Error: ${e.toString()}';
    }
  }
}
