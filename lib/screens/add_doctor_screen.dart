import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class AddDoctorScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;
  final String? preselectedClinicId; // auto-fill klinik saat dibuka dari halaman klinik

  const AddDoctorScreen({super.key, this.docId, this.initialData, this.preselectedClinicId});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController spesialisController = TextEditingController();
  
  String? selectedClinicId;
  bool isLoading = false;

  bool get _isEditMode => widget.docId != null;

  @override
  void initState() {
    super.initState();
    // Auto-set klinik jika dibuka dari halaman klinik
    if (widget.preselectedClinicId != null) {
      selectedClinicId = widget.preselectedClinicId;
    }
    if (_isEditMode && widget.initialData != null) {
      nameController.text = widget.initialData!['name'] ?? '';
      emailController.text = widget.initialData!['email'] ?? '';
      spesialisController.text = widget.initialData!['spesialis'] ?? '';
      selectedClinicId = widget.initialData!['clinicId'] ?? widget.preselectedClinicId;
    }
  }


  Future<void> submit() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String spesialis = spesialisController.text.trim();

    if (_isEditMode) {
      if (name.isEmpty || spesialis.isEmpty || selectedClinicId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua data & pilih klinik!")));
        return;
      }
    } else {
      if (name.isEmpty || email.isEmpty || password.isEmpty || spesialis.isEmpty || selectedClinicId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua data & pilih klinik!")));
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (_isEditMode) {
        await FirebaseFirestore.instance.collection('users').doc(widget.docId).update({
          'name': name,
          'spesialis': spesialis,
          'clinicId': selectedClinicId,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Dokter berhasil diperbarui!")));
          Navigator.pop(context);
        }
      } else {
        // Initialize Secondary App to prevent logging out Admin
        FirebaseApp secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryAppDoc_${DateTime.now().millisecondsSinceEpoch}',
          options: Firebase.app().options,
        );

        UserCredential cred = await FirebaseAuth.instanceFor(app: secondaryApp)
            .createUserWithEmailAndPassword(email: email, password: password);

        // Save to Firestore using Primary App
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': name,
          'email': email,
          'role': 'dokter',
          'spesialis': spesialis,
          'clinicId': selectedClinicId,
          'isOnline': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Cleanup
        await secondaryApp.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dokter berhasil ditambahkan!")));
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
      appBar: AppBar(title: Text(_isEditMode ? "Edit Data Dokter" : "Tambah Dokter Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nama Dokter", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: nameController, decoration: const InputDecoration(hintText: "Contoh: drh. Budi Setiawan")),
            const SizedBox(height: 15),
            
            if (!_isEditMode) ...[
              const Text("Email Login", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: "drhbudi@vetra.com")),
              const SizedBox(height: 15),

              const Text("Password Login", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(hintText: "Minimal 6 karakter")),
              const SizedBox(height: 15),
            ],

            const Text("Spesialisasi", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: spesialisController, decoration: const InputDecoration(hintText: "Contoh: Dokter Hewan Kecil")),
            const SizedBox(height: 15),

            const Text("Pilih Klinik Penempatan", style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'klinik').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("Belum ada klinik yang terdaftar. Tambahkan klinik dulu.", style: TextStyle(color: Colors.red));
                }

                final clinics = snapshot.data!.docs;
                // Pastikan selectedClinicId masih valid
                if (selectedClinicId != null && !clinics.any((c) => c.id == selectedClinicId)) {
                  selectedClinicId = null;
                }

                return DropdownButtonFormField<String>(
                  value: selectedClinicId,
                  hint: const Text("Pilih Klinik"),
                  items: clinics.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name'] ?? 'Tanpa Nama'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedClinicId = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: isLoading ? null : submit,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(_isEditMode ? "Update Dokter" : "Simpan Dokter", style: const TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
