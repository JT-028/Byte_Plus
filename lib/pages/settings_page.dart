// lib/pages/settings_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _radius = TextEditingController();
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userSnap.data();
    _isAdmin = (userData?['role'] ?? '') == 'admin';

    final cfg =
        await FirebaseFirestore.instance.collection('config').doc('app').get();
    final center = (cfg.data()?['schoolCenter'] as Map?) ?? {};
    _lat.text =
        ((center['lat'] as num?)?.toDouble() ?? 15.158503947241618).toString();
    _lng.text =
        ((center['lng'] as num?)?.toDouble() ?? 120.59252284294321).toString();
    _radius.text =
        ((cfg.data()?['radiusMeters'] as num?)?.toDouble() ?? 150).toString();

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final lat = double.tryParse(_lat.text.trim()) ?? 0;
    final lng = double.tryParse(_lng.text.trim()) ?? 0;
    final radius = double.tryParse(_radius.text.trim()) ?? 150;

    await FirebaseFirestore.instance.collection('config').doc('app').set({
      'schoolCenter': {'lat': lat, 'lng': lng},
      'radiusMeters': radius,
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Geofence updated.')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Profile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (_, snap) {
              final data = snap.data?.data() ?? {};
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text('${data['email']} • ${data['role']}'),
              );
            },
          ),
          const Divider(height: 32),

          if (_isAdmin) ...[
            const Text('Geofence Settings (Admin Only)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _lat,
              decoration: const InputDecoration(labelText: 'School Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lng,
              decoration: const InputDecoration(labelText: 'School Longitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _radius,
              decoration: const InputDecoration(labelText: 'Radius (meters)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Geofence'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            ),
          ],
        ],
      ),
    );
  }
}
