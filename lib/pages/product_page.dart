// lib/pages/product_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
  final String storeId;
  final String productId;

  const ProductPage({
    super.key,
    required this.storeId,
    required this.productId,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  DocumentSnapshot? doc;

  // Size price now represents FULL PRICE (100 / 110)
  int selectedSizePrice = 0;
  String? selectedSize;

  // Required fields
  String? selectedSugar;
  String? selectedIce;

  // Optional
  final Set<Map<String, dynamic>> selectedToppings = {};
  int toppingsTotal = 0;

  int quantity = 1;
  int basePrice = 0; // Regular full price
  bool collapsed = false;

  final TextEditingController noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProduct();
  }

  Future<void> loadProduct() async {
    final snap =
        await FirebaseFirestore.instance
            .collection("stores")
            .doc(widget.storeId)
            .collection("menu")
            .doc(widget.productId)
            .get();

    if (snap.exists) {
      setState(() {
        doc = snap;
        basePrice = int.parse(snap["price"].toString());
      });
    }
  }

  // ------------------------------------------------------------
  // REQUIRED LOGIC
  // ------------------------------------------------------------
  bool isCompleted(String section) {
    switch (section) {
      case "size":
        return selectedSize != null;
      case "sugar":
        return selectedSugar != null;
      case "ice":
        return selectedIce != null;
      default:
        return false;
    }
  }

  // ------------------------------------------------------------
  // TOTAL PRICE LOGIC (Option B — FULL PRICE)
  // ------------------------------------------------------------
  int get appliedSizePrice =>
      selectedSizePrice > 0 ? selectedSizePrice : basePrice;

  int computeTotal() {
    return (appliedSizePrice + toppingsTotal) * quantity;
  }

  bool sameToppings(List a, List b) {
    if (a.length != b.length) return false;
    final A = a.map((e) => e.toString()).toList()..sort();
    final B = b.map((e) => e.toString()).toList()..sort();
    return A.toString() == B.toString();
  }

  Future<void> addToCart() async {
    if (doc == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cartRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("cartItems");

    final toppingsList = selectedToppings.toList();

    final match =
        await cartRef
            .where("storeId", isEqualTo: widget.storeId)
            .where("productId", isEqualTo: widget.productId)
            .where("sizeName", isEqualTo: selectedSize ?? "")
            .where("sugarLevel", isEqualTo: selectedSugar ?? "")
            .where("iceLevel", isEqualTo: selectedIce ?? "")
            .get();

    bool merged = false;

    for (var x in match.docs) {
      final data = x.data();
      final existingT = List.from(data["toppings"] ?? []);

      if (sameToppings(existingT, toppingsList)) {
        int newQty = (data["quantity"] ?? 1) + quantity;

        await x.reference.update({
          "quantity": newQty,
          "lineTotal": newQty * (appliedSizePrice + toppingsTotal),
        });

        merged = true;
        break;
      }
    }

    if (!merged) {
      await cartRef.add({
        "storeId": widget.storeId,
        "productId": widget.productId,
        "productName": doc!["name"],
        "imageUrl": doc!["imageUrl"],
        "basePrice": appliedSizePrice,
        "sizeName": selectedSize ?? "",
        "sizePrice": appliedSizePrice,
        "sugarLevel": selectedSugar ?? "",
        "iceLevel": selectedIce ?? "",
        "toppings": toppingsList,
        "toppingsTotal": toppingsTotal,
        "note": noteCtrl.text.trim(),
        "quantity": quantity,
        "lineTotal": computeTotal(),
        "createdAt": DateTime.now(),
      });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (doc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = doc!.data() as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _sliverHeader(data),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildBody(data),
                    ),
                  ),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------
  SliverAppBar _sliverHeader(Map data) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 260,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.close, color: Colors.black),
          ),
        ),
      ),
      title: AnimatedOpacity(
        opacity: collapsed ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(data["name"], style: const TextStyle(color: Colors.black)),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, c) {
          bool collapse = c.biggest.height < 150;

          if (collapse != collapsed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => collapsed = collapse);
            });
          }

          return FlexibleSpaceBar(
            background: Center(
              child: Image.network(
                data["imageUrl"],
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // BODY
  // ------------------------------------------------------------
  Widget _buildBody(Map data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data["name"],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),

        // PRICE DISPLAY (FIXED)
        Text(
          "₱$appliedSizePrice",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),

        const SizedBox(height: 20),

        // DESCRIPTION
        if (data["description"] != null)
          Text(
            data["description"],
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),

        const SizedBox(height: 25),

        // SIZE REQUIRED
        _sectionTitle("Size", required: true, keyName: "size"),
        _container(
          Column(
            children: List.generate(data["size"].length, (i) {
              final s = data["size"][i];
              return RadioListTile(
                title: Text("${s["name"]}  (₱${s["price"]})"),
                value: s["name"],
                groupValue: selectedSize,
                onChanged: (v) {
                  setState(() {
                    selectedSize = v.toString();
                    selectedSizePrice = int.parse(s["price"].toString());
                  });
                },
              );
            }),
          ),
        ),

        const SizedBox(height: 25),

        // SUGAR REQUIRED
        _sectionTitle("Sugar Level", required: true, keyName: "sugar"),
        _container(
          Wrap(
            spacing: 10,
            children: List.generate(data["sugarOptions"].length, (i) {
              final opt = data["sugarOptions"][i];
              return ChoiceChip(
                label: Text(opt),
                selected: selectedSugar == opt,
                onSelected: (_) => setState(() => selectedSugar = opt),
              );
            }),
          ),
        ),

        const SizedBox(height: 25),

        // ICE REQUIRED
        _sectionTitle("Ice Level", required: true, keyName: "ice"),
        _container(
          Wrap(
            spacing: 10,
            children: List.generate(data["iceOptions"].length, (i) {
              final opt = data["iceOptions"][i];
              return ChoiceChip(
                label: Text(opt),
                selected: selectedIce == opt,
                onSelected: (_) => setState(() => selectedIce = opt),
              );
            }),
          ),
        ),

        const SizedBox(height: 25),

        // TOPPINGS OPTIONAL
        _sectionTitle("Toppings"),
        _container(
          Column(
            children: List.generate(data["toppings"].length, (i) {
              final t = data["toppings"][i];
              final added = selectedToppings.any((x) => x["name"] == t["name"]);
              return CheckboxListTile(
                title: Text("${t["name"]}  (+₱${t["price"]})"),
                value: added,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selectedToppings.add(t);
                    } else {
                      selectedToppings.removeWhere(
                        (x) => x["name"] == t["name"],
                      );
                    }
                    toppingsTotal = selectedToppings.fold(
                      0,
                      (sum, x) => sum + int.parse(x["price"].toString()),
                    );
                  });
                },
              );
            }),
          ),
        ),

        const SizedBox(height: 25),

        _sectionTitle("Note to Vendor"),
        _container(
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Add your request (optional)",
            ),
          ),
        ),

        const SizedBox(height: 140),
      ],
    );
  }

  // ------------------------------------------------------------
  // SECTION TITLE UI
  // ------------------------------------------------------------
  Widget _sectionTitle(
    String text, {
    bool required = false,
    String keyName = "",
  }) {
    bool done = required ? isCompleted(keyName) : false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (required)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: done ? Colors.grey.shade300 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              done ? "Completed" : "Required",
              style: TextStyle(
                color: done ? Colors.black54 : Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Optional",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
      ],
    );
  }

  Widget _container(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------
  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // QUANTITY
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed:
                      quantity > 1 ? () => setState(() => quantity--) : null,
                ),
                Text(
                  "$quantity",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ADD TO CART
          Expanded(
            child: ElevatedButton(
              onPressed:
                  isCompleted("size") &&
                          isCompleted("sugar") &&
                          isCompleted("ice")
                      ? addToCart
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF375DFB),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                "Add to cart • ₱${computeTotal()}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
