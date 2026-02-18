import 'package:flutter/material.dart';

class PlaceholderStorePage extends StatelessWidget {
  final String storeName;
  const PlaceholderStorePage({super.key, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
        backgroundColor: const Color(0xFF1F41BB),
      ),
      body: const Center(
        child: Text("Store Page UI Coming Soon!",
            style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
