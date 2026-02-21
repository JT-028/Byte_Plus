// lib/pages/personal_info_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/app_modal_dialog.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = user.uid;
    final snap =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    final data = snap.data() ?? {};
    nameCtrl.text = data["name"] ?? "";
    emailCtrl.text = user.email ?? "";
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SAVE PROFILE
  // ---------------------------------------------------------------------------
  Future<void> _saveProfile() async {
    setState(() => saving = true);

    final uid = user.uid;
    final originalEmail = user.email!;
    final domain = "@canteen.spcf.co";

    // Make sure email stays within domain
    String editedEmail = emailCtrl.text.trim();
    if (!editedEmail.endsWith(domain)) {
      editedEmail = "${editedEmail.split('@')[0]}$domain";
    }

    try {
      // Update Firestore (name + email)
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "name": nameCtrl.text.trim(),
        "email": editedEmail,
      });

      // Update FirebaseAuth email (only local part changes)
      if (originalEmail != editedEmail) {
        await user.updateEmail(editedEmail);
      }

      _success("Profile updated!");
    } catch (e) {
      _error("Failed to update profile.");
    }

    setState(() => saving = false);
  }

  // ---------------------------------------------------------------------------
  // CHANGE PASSWORD SHEET
  // ---------------------------------------------------------------------------
  void _showChangePasswordSheet() {
    final currentPw = TextEditingController();
    final newPw = TextEditingController();
    final confirmPw = TextEditingController();

    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: bottomInset + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Change Password",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),

                  // CURRENT PASSWORD
                  TextField(
                    controller: currentPw,
                    obscureText: !showCurrent,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showCurrent ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed:
                            () => modalSetState(() {
                              showCurrent = !showCurrent;
                            }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // NEW PASSWORD
                  TextField(
                    controller: newPw,
                    obscureText: !showNew,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNew ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed:
                            () => modalSetState(() {
                              showNew = !showNew;
                            }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CONFIRM PASSWORD
                  TextField(
                    controller: confirmPw,
                    obscureText: !showConfirm,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirm ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed:
                            () => modalSetState(() {
                              showConfirm = !showConfirm;
                            }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (newPw.text != confirmPw.text) {
                          _error("New passwords do not match.");
                          return;
                        }
                        if (newPw.text.length < 6) {
                          _error("Password must be at least 6 characters.");
                          return;
                        }

                        try {
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPw.text,
                          );

                          // Re-authenticate
                          await user.reauthenticateWithCredential(cred);

                          // Update password
                          await user.updatePassword(newPw.text);

                          Navigator.pop(context);
                          _success("Password changed successfully!");
                        } catch (e) {
                          _error(_firebaseError(e.toString()));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Password",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------
  void _error(String msg) {
    AppModalDialog.error(context: context, title: 'Error', message: msg);
  }

  void _success(String msg) {
    AppModalDialog.success(context: context, title: 'Success', message: msg);
  }

  String _firebaseError(String e) {
    if (e.contains("wrong-password")) return "Incorrect current password.";
    if (e.contains("weak-password")) return "Password too weak.";
    return "Something went wrong.";
  }

  // ---------------------------------------------------------------------------
  // MAIN UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        title: Text(
          "Personal Info",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NAME FIELD
            const Text(
              "Full Name",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // EMAIL FIELD
            const Text(
              "Email",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              onChanged: (v) {
                final domain = "@canteen.spcf.co";
                if (!v.contains(domain)) {
                  setState(() {
                    emailCtrl.text = "${v.split('@')[0]}$domain";
                    emailCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: emailCtrl.text.split('@')[0].length),
                    );
                  });
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                    saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 20),

            // CHANGE PASSWORD
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _showChangePasswordSheet,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
