import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  bool _showConfirm = false;

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final username = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMsg("Please fill in all fields.");
      return;
    }

    if (username.contains("@")) {
      _showMsg("Do NOT include '@'. We will add it automatically.");
      return;
    }

    if (password != confirm) {
      _showMsg("Passwords do not match.");
      return;
    }

    final email = "$username@canteen.spcf.co";

    try {
      setState(() => _loading = true);

      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': 'student',
        'createdAt': DateTime.now(),
      });

      _showMsg("Account created successfully!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      _showMsg(e.message ?? "Registration failed.");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset("assets/images/spcf_logo.png", width: 120),
              const SizedBox(height: 10),
              const Text(
                "Byte Plus",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              _textField(_nameCtrl, "Full Name"),
              _textField(_emailCtrl, "School Email (without @canteen.spcf.co)"),

              // PASSWORD
              _passwordField(
                controller: _passCtrl,
                hint: "Password",
                visible: _showPass,
                onToggle: () => setState(() => _showPass = !_showPass),
              ),

              // CONFIRM PASSWORD
              _passwordField(
                controller: _confirmCtrl,
                hint: "Confirm Password",
                visible: _showConfirm,
                onToggle: () => setState(() => _showConfirm = !_showConfirm),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F41BB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign up", style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginPage())),
                child: const Text("Already have an account?"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
