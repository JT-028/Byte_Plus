import 'package:flutter/material.dart';

import '../widgets/app_modal_dialog.dart';

class FoodDetailPopup extends StatefulWidget {
  final String name;
  final double price;
  final Function(Map<String, dynamic>) onAddToCart;

  const FoodDetailPopup({
    super.key,
    required this.name,
    required this.price,
    required this.onAddToCart,
  });

  @override
  State<FoodDetailPopup> createState() => _FoodDetailPopupState();
}

class _FoodDetailPopupState extends State<FoodDetailPopup> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          const Icon(Icons.fastfood, color: Colors.orange, size: 80),
          const SizedBox(height: 10),
          Text(
            widget.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${widget.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No description available.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 30),
                onPressed: () {
                  if (qty > 1) setState(() => qty--);
                },
              ),
              Text(
                '$qty',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 30),
                onPressed: () => setState(() => qty++),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                for (int i = 0; i < qty; i++) {
                  widget.onAddToCart({
                    'name': widget.name,
                    'price': widget.price,
                  });
                }
                Navigator.pop(context);
                AppModalDialog.success(
                  context: context,
                  title: 'Added to Cart',
                  message: '${widget.name} has been added to your cart.',
                );
              },
              child: const Text(
                'Add to Cart',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
