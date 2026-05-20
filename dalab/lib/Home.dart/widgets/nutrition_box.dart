import 'package:flutter/material.dart';

Widget nutriBox(String title, String value) {
  return Container(
    width: 80,
    padding: EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12)),
      ],
    ),
  );
}
