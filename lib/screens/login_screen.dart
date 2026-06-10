import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = true;
  bool isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.primary),
            SizedBox(width: 10),
            Text("Reset Password", style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan email Anda. Link reset password akan dikirimkan ke email tersebut.",
              style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter your email",
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: AppColors.darkGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email tidak boleh kosong!")),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Link reset password telah dikirim ke email Anda!"),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal mengirim email: $e")),
                  );
                }
              }
            },
            child: const Text("Kirim Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 🔵 Background
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
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
                SizedBox(height: MediaQuery.of(context).padding.top + 40),

                // 🐾 Logo
                Column(
                  children: [
                    const Icon(Icons.pets, size: 80, color: AppColors.white),
                    const SizedBox(height: 10),
                    Text(
                      "Vetra",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.white,
                        fontSize: 36,
                      ),
                    ),
                    Text(
                      "Veterinary & Pet Care Application",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

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

                      Text("Password", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Enter your password",
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

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: rememberMe,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("Remember Me", style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // 🔘 Login Button
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
                          onPressed: isLoading ? null : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text("Email & Password wajib diisi")),
                              );
                              return;
                            }
                            setState(() => isLoading = true);
                            try {
                              final auth = AuthService();
                              var user = await auth.login(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                              );
                              if (user == null && mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text("Login gagal")),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => isLoading = false);
                            }
                          },
                          child: isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                            : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                            setState(() => isLoading = true);
                            try {
                              final auth = AuthService();
                              final user = await auth.signInWithGoogle();
                              if (user == null && mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text("Login dengan Google dibatalkan.")),
                                );
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
                            "Masuk dengan Google",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 🔗 Forgot Password
                      Center(
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            "Lupa Password?",
                            style: TextStyle(color: AppColors.darkGrey, fontSize: 13),
                          ),
                        ),
                      ),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            "Belum punya akun? Daftar",
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