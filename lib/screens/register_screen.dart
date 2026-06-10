import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 🔵 Header background — sama seperti login
          Container(
            height: MediaQuery.of(context).size.height * 0.42,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 30),

                // 🔙 Back button + Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(Icons.pets, size: 60, color: AppColors.white),
                        const SizedBox(height: 8),
                        Text(
                          "Vetra",
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.white,
                            fontSize: 30,
                          ),
                        ),
                        Text(
                          "Buat Akun Baru",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 📋 Form Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grey.withValues(alpha: 0.5),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama
                      Text("Nama Lengkap", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: "Masukkan nama lengkap Anda",
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Email
                      Text("Email", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: "Enter your email",
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password
                      Text("Password", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Minimal 6 karakter",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.darkGrey,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Konfirmasi Password
                      Text("Konfirmasi Password", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: "Ulangi password Anda",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.darkGrey,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 🔘 Daftar Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryOrange,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);

                                  if (nameController.text.trim().isEmpty ||
                                      emailController.text.trim().isEmpty ||
                                      passwordController.text.isEmpty) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text("Semua kolom wajib diisi!")),
                                    );
                                    return;
                                  }

                                  if (passwordController.text != confirmPasswordController.text) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text("Password dan konfirmasi tidak sama!")),
                                    );
                                    return;
                                  }

                                  if (passwordController.text.length < 6) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text("Password minimal 6 karakter!")),
                                    );
                                    return;
                                  }

                                  setState(() => isLoading = true);

                                  try {
                                    final auth = AuthService();
                                    var user = await auth.register(
                                      emailController.text.trim(),
                                      passwordController.text.trim(),
                                      nameController.text.trim(),
                                    );

                                    if (user != null && mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("✅ Registrasi berhasil! Selamat datang di Vetra."),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                      navigator.popUntil((route) => route.isFirst);
                                    }
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  } finally {
                                    if (mounted) setState(() => isLoading = false);
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Daftar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ─── OR divider ───
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text("atau", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 🔵 Google Sign-In Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: isLoading ? null : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            setState(() => isLoading = true);
                            try {
                              final auth = AuthService();
                              final user = await auth.signInWithGoogle();
                              if (user == null && mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text("Daftar dengan Google dibatalkan.")),
                                );
                              } else if (user != null && mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text("✅ Berhasil masuk dengan Google!"),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                                navigator.popUntil((route) => route.isFirst);
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                              }
                            } finally {
                              if (mounted) setState(() => isLoading = false);
                            }
                          },
                          icon: Image.network(
                            'https://www.google.com/favicon.ico',
                            width: 20,
                            height: 20,
                            errorBuilder: (ctx, e, s) => const Icon(Icons.g_mobiledata, size: 22, color: Colors.red),
                          ),
                          label: const Text(
                            "Daftar dengan Google",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Sudah punya akun? Login",
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}