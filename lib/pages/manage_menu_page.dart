// lib/pages/manage_menu_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageMenuPage extends StatefulWidget {
  const ManageMenuPage({super.key});

  @override
  State<ManageMenuPage> createState() => _ManageMenuPageState();
}

class _ManageMenuPageState extends State<ManageMenuPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  Future<void> _addOrEditItem({String? id}) async {
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    if (name.isEmpty || priceText.isEmpty) return;

    final price = double.tryParse(priceText) ?? 0;
    final collection = FirebaseFirestore.instance.collection('menu');

    if (id == null) {
      await collection.add({
        'name': name,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Item added.')));
    } else {
      await collection.doc(id).update({
        'name': name,
        'price': price,
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Item updated.')));
    }

    nameController.clear();
    priceController.clear();
    Navigator.pop(context);
  }

  void _showAddEditDialog({String? id, String? currentName, double? currentPrice}) {
    nameController.text = currentName ?? '';
    priceController.text = currentPrice?.toString() ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Add Item' : 'Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => _addOrEditItem(id: id),
            child: Text(id == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menu')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Failed to load menu.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No items yet.'));

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final price = (data['price'] as num?)?.toDouble() ?? 0;

              return Card(
                color: Colors.orange.shade100,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.fastfood, color: Colors.orange, size: 40),
                          const SizedBox(height: 8),
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('₱${price.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.orange)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddEditDialog(
                                id: docs[i].id,
                                currentName: name,
                                currentPrice: price),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await docs[i].reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Item deleted.')));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
