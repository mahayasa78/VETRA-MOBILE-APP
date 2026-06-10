import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class AddClinicScreen extends StatefulWidget {
  final String? clinicId;
  final Map<String, dynamic>? initialData;

  const AddClinicScreen({super.key, this.clinicId, this.initialData});

  @override
  State<AddClinicScreen> createState() => _AddClinicScreenState();
}

class _AddClinicScreenState extends State<AddClinicScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  
  bool isLoading = false;

  bool get _isEditMode => widget.clinicId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode && widget.initialData != null) {
      nameController.text = widget.initialData!['name'] ?? '';
      emailController.text = widget.initialData!['email'] ?? '';
      addressController.text = widget.initialData!['address'] ?? '';
      descController.text = widget.initialData!['description'] ?? '';
      hoursController.text = widget.initialData!['operatingHours'] ?? '';
    }
  }

  Future<void> submit() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String address = addressController.text.trim();
    String desc = descController.text.trim();
    String hours = hoursController.text.trim();

    if (_isEditMode) {
      if (name.isEmpty || address.isEmpty || desc.isEmpty || hours.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua data!")));
        return;
      }
    } else {
      if (name.isEmpty || email.isEmpty || password.isEmpty || address.isEmpty || desc.isEmpty || hours.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua data!")));
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (_isEditMode) {
        await FirebaseFirestore.instance.collection('users').doc(widget.clinicId).update({
          'name': name,
          'address': address,
          'description': desc,
          'operatingHours': hours,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Klinik berhasil diperbarui!")));
          Navigator.pop(context);
        }
      } else {
        // Initialize Secondary App to prevent logging out Admin
        FirebaseApp secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryAppClinic_${DateTime.now().millisecondsSinceEpoch}',
          options: Firebase.app().options,
        );

        UserCredential cred = await FirebaseAuth.instanceFor(app: secondaryApp)
            .createUserWithEmailAndPassword(email: email, password: password);

        // Save to Firestore using Primary App
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': name,
          'email': email,
          'role': 'klinik',
          'address': address,
          'description': desc,
          'operatingHours': hours,
          'isClinicOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Cleanup
        await secondaryApp.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Klinik berhasil ditambahkan!")));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? "Edit Data Klinik" : "Tambah Klinik Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nama Klinik", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: nameController, decoration: const InputDecoration(hintText: "Contoh: Klinik Hewan Sehat")),
            const SizedBox(height: 15),
            
            if (!_isEditMode) ...[
              const Text("Email Login", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: "email@klinik.com")),
              const SizedBox(height: 15),

              const Text("Password Login", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(hintText: "Minimal 6 karakter")),
              const SizedBox(height: 15),
            ],

            const Text("Alamat", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: addressController, decoration: const InputDecoration(hintText: "Alamat lengkap klinik")),
            const SizedBox(height: 15),

            const Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(hintText: "Fasilitas, keunggulan, dll")),
            const SizedBox(height: 15),

            const Text("Jam Operasional", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: hoursController, decoration: const InputDecoration(hintText: "Contoh: Senin-Sabtu 08:00 - 20:00")),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: isLoading ? null : submit,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(_isEditMode ? "Update Klinik" : "Simpan Klinik", style: const TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
