import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';

class BookingScreen extends StatefulWidget {
  final String? preselectedClinicId;
  final String? preselectedClinicName;

  const BookingScreen({super.key, this.preselectedClinicId, this.preselectedClinicName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedClinicId;
  String? selectedDoctorId;
  String? selectedPetName;
  DateTime? selectedDate;
  String? selectedTime;
  bool isLoading = false;
  final TextEditingController _complaintController = TextEditingController();

  List<Map<String, dynamic>> userPets = [];
  bool isLoadingPets = true;

  final List<String> times = [
    "09:00",
    "10:00",
    "11:00",
    "13:00",
    "14:00",
  ];

  @override
  void initState() {
    super.initState();
    // Auto-fill klinik jika dibuka dari halaman klinik
    if (widget.preselectedClinicId != null) {
      selectedClinicId = widget.preselectedClinicId;
    }
    _fetchPets();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _fetchPets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('pets')
            .get();
        if (mounted) {
          setState(() {
            userPets = snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'] ?? 'Tanpa Nama',
              };
            }).toList();
            isLoadingPets = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => isLoadingPets = false);
      }
    } else {
      if (mounted) setState(() => isLoadingPets = false);
    }
  }

  // 📅 pilih tanggal
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> submitBooking(List<QueryDocumentSnapshot<Object?>> clinics, List<QueryDocumentSnapshot<Object?>> doctors) async {
    if (selectedClinicId == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data (klinik, tanggal, dan jam)!")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String doctorName = 'Belum ditentukan';
        if (selectedDoctorId != null && doctors.isNotEmpty) {
          try {
            final selectedDoctorDoc = doctors.firstWhere((doc) => doc.id == selectedDoctorId);
            doctorName = (selectedDoctorDoc.data() as Map<String, dynamic>)['name'] ?? 'Dokter';
          } catch (e) {
            doctorName = 'Belum ditentukan';
          }
        }

        final selectedClinicDoc = clinics.firstWhere((doc) => doc.id == selectedClinicId);
        final clinicName = (selectedClinicDoc.data() as Map<String, dynamic>)['name'] ?? 'Klinik';

        // Fetch user name
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userName = (userDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Pasien';

        // Parse time to combine with date
        final timeParts = selectedTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final scheduledAtDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          hour,
          minute,
        );

        await FirebaseFirestore.instance.collection('bookings').add({
          'userId': user.uid,
          'userName': userName,
          'doctorId': selectedDoctorId,
          'doctorName': doctorName,
          'clinicId': selectedClinicId,
          'clinicName': clinicName,
          'petName': selectedPetName ?? 'Tanpa peliharaan',
          'complaint': _complaintController.text.trim(),
          'date': Timestamp.fromDate(selectedDate!),
          'time': selectedTime,
          'scheduledAt': Timestamp.fromDate(scheduledAtDateTime),
          'status': 'Menunggu', // Default status
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Booking berhasil! Menunggu konfirmasi klinik.")),
          );
          Navigator.pop(context); // Return to previous screen
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal booking: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _autoHealDoctorData(List<QueryDocumentSnapshot<Object?>> doctors, List<QueryDocumentSnapshot<Object?>> clinics) async {
    if (clinics.isEmpty) return;
    
    for (var doc in doctors) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['clinicId'] == null || data['clinicId'].toString().isEmpty) {
        // Assign to the first clinic
        await FirebaseFirestore.instance.collection('users').doc(doc.id).update({
          'clinicId': clinics.first.id,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Konsultasi")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', whereIn: ['klinik', 'dokter'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || isLoadingPets) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Data klinik atau dokter tidak ditemukan."));
            }

            final allDocs = snapshot.data!.docs;
            final clinics = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'klinik').toList();
            final doctors = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'dokter').toList();

            // Auto-heal doctors without clinicId
            _autoHealDoctorData(doctors, clinics);

            // Filter doctors based on selected clinic
            List<QueryDocumentSnapshot<Object?>> filteredDoctors = doctors;
            if (selectedClinicId != null) {
              filteredDoctors = doctors.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['clinicId'] == selectedClinicId;
              }).toList();
            }

            // Make sure selections are still valid
            if (selectedClinicId != null && !clinics.any((doc) => doc.id == selectedClinicId)) {
              selectedClinicId = null;
            }
            if (selectedDoctorId != null && !filteredDoctors.any((doc) => doc.id == selectedDoctorId)) {
              selectedDoctorId = null;
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏥 PILIH KLINIK
                  const Text("Pilih Klinik", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: selectedClinicId,
                    hint: const Text("Pilih klinik"),
                    items: clinics.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Klinik'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClinicId = value;
                        selectedDoctorId = null; // Reset doctor when clinic changes
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 👨‍⚕️ PILIH DOKTER (Opsional)
                  const Text("Pilih Dokter", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text("Opsional — kosongkan jika ingin dokter ditentukan klinik",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  DropdownButtonFormField<String>(
                    value: selectedDoctorId,
                    hint: const Text("Pilih dokter (opsional)"),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Tidak memilih dokter"),
                      ),
                      ...filteredDoctors.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['name'] ?? 'Dokter'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedDoctorId = value;
                        // Auto-select clinic if not already selected
                        if (selectedDoctorId != null && selectedClinicId == null) {
                          try {
                            final selectedDoc = doctors.firstWhere((doc) => doc.id == selectedDoctorId);
                            final data = selectedDoc.data() as Map<String, dynamic>;
                            if (data['clinicId'] != null) {
                              selectedClinicId = data['clinicId'];
                            }
                          } catch (e) {
                            // Doctor not found, ignore
                          }
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 🐾 PILIH PELIHARAAN
                  const Text("Pilih Peliharaan", style: TextStyle(fontWeight: FontWeight.bold)),
                  if (userPets.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Anda belum menambahkan hewan peliharaan di Profil. (Anda tetap bisa melanjutkan booking tanpa peliharaan)",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedPetName,
                      hint: const Text("Pilih peliharaan"),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("Tanpa peliharaan"),
                        ),
                        ...userPets.map((pet) {
                          return DropdownMenuItem<String>(
                            value: pet['name'] as String,
                            child: Text(pet['name'] as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedPetName = value;
                        });
                      },
                    ),

                  const SizedBox(height: 20),

                  // 📅 PILIH TANGGAL
                  const Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedDate == null
                            ? "Pilih tanggal"
                            : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⏰ PILIH JAM
                  const Text("Jam Konsultasi", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: times.map((time) {
                      final isSelected = selectedTime == time;
                      return ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedTime = time;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 📝 KELUHAN
                  const Text("Keluhan (Opsional)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _complaintController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Jelaskan gejala atau keluhan hewan...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔥 BUTTON BOOKING
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => submitBooking(clinics, doctors),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Booking Sekarang"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}