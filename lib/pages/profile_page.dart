// lib/pages/profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'favorites_page.dart';
import 'personal_info_page.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const kBrandBlue = Color(0xFF1F41BB);

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
          builder: (context, snap) {
            final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};

            final displayName = (data['name'] ?? '').toString().trim();
            final email =
                (data['email'] ??
                        FirebaseAuth.instance.currentUser?.email ??
                        '')
                    .toString()
                    .trim();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerCard(
                  name: displayName.isEmpty ? "Unnamed User" : displayName,
                  email: email,
                ),
                const SizedBox(height: 14),

                _listTile(
                  icon: Icons.favorite_border,
                  title: "Favourites",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()),
                    );
                  },
                ),
                _listTile(
                  icon: Icons.person_outline,
                  title: "Personal Info",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalInfoPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Dark mode placeholder toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 22),
                      const SizedBox(width: 16),
                      const Text("Dark Mode", style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      Switch(
                        value: false,
                        activeThumbColor: kBrandBlue,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                _logoutButton(context),
                const SizedBox(height: 22),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _headerCard({required String name, required String email}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kBrandBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;

            // Optional: force navigation to login to avoid any weird backstack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
          child: const Text(
            "Log Out",
            style: TextStyle(color: kBrandBlue, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
