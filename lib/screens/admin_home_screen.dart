import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_article_screen.dart';
import 'add_doctor_screen.dart';
import 'add_clinic_screen.dart';
import 'admin_user_list_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Overview"),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: "Dokter"),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: "Klinik"),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "Artikel"),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return _buildOverview();
    } else if (_selectedIndex == 1) {
      return _buildDoctorManageList();
    } else if (_selectedIndex == 2) {
      return _buildClinicManageList();
    } else {
      return _buildArticleManageList();
    }
  }

  Widget _buildOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('articles').snapshots(),
          builder: (context, articleSnap) {
            int usersCount = 0;
            int doctorsCount = 0;
            int clinicsCount = 0;
            int articlesCount = 0;

            if (userSnap.hasData) {
              final docs = userSnap.data!.docs;
              usersCount = docs.where((d) => (d.data() as Map)['role'] == 'user').length;
              doctorsCount = docs.where((d) => (d.data() as Map)['role'] == 'dokter').length;
              clinicsCount = docs.where((d) => (d.data() as Map)['role'] == 'klinik').length;
            }

            if (articleSnap.hasData) {
              articlesCount = articleSnap.data!.docs.length;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sistem VETRA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Ringkasan Data Aplikasi", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  // Donut Chart Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: DonutChart(
                        users: usersCount.toDouble(),
                        doctors: doctorsCount.toDouble(),
                        clinics: clinicsCount.toDouble(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        usersCount.toString(),
                        "Total User",
                        Icons.people,
                        Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminUserListScreen()),
                          );
                        },
                      ),
                      _buildStatCard(
                        doctorsCount.toString(),
                        "Total Dokter",
                        Icons.medical_services,
                        Colors.teal,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),
                      _buildStatCard(
                        clinicsCount.toString(),
                        "Total Klinik",
                        Icons.local_hospital,
                        Colors.orange,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                        },
                      ),
                      _buildStatCard(
                        articlesCount.toString(),
                        "Artikel Edukasi",
                        Icons.article,
                        Colors.purple,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 3;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon, Color color, {required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorManageList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Kelola Dokter", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddDoctorScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah"),
              )
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'dokter').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada data dokter."));
                }

                final doctors = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE6F7F7),
                          child: Icon(Icons.medical_services, color: Colors.teal),
                        ),
                        title: Text(data['name'] ?? 'Tanpa Nama'),
                        subtitle: Text(data['spesialis'] ?? 'Dokter Hewan'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddDoctorScreen(
                                      docId: doc.id,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Hapus Dokter"),
                                    content: const Text("Anda yakin ingin menghapus dokter ini?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ) ?? false;

                                if (confirm) {
                                  await FirebaseFirestore.instance.collection('users').doc(doc.id).delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildClinicManageList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Kelola Klinik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddClinicScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah"),
              )
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'klinik').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada data klinik."));
                }

                final clinics = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: clinics.length,
                  itemBuilder: (context, index) {
                    final doc = clinics[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFF3E0),
                          child: Icon(Icons.local_hospital, color: Colors.orange),
                        ),
                        title: Text(data['name'] ?? 'Tanpa Nama'),
                        subtitle: Text(data['address'] ?? 'Alamat tidak diketahui'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddClinicScreen(
                                      clinicId: doc.id,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Hapus Klinik"),
                                    content: const Text("Anda yakin ingin menghapus klinik ini?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ) ?? false;

                                if (confirm) {
                                  await FirebaseFirestore.instance.collection('users').doc(doc.id).delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // 🔥 FITUR ARTIKEL ASLI
  Widget _buildArticleManageList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Kelola Artikel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddArticleScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah"),
              )
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('articles').orderBy('created_at', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada artikel."));
                }

                final articles = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final articleDoc = articles[index];
                    final articleData = articleDoc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE6F7F7),
                          child: Icon(Icons.article, color: Colors.teal),
                        ),
                        title: Text(articleData['title'] ?? 'Tanpa Judul', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(articleData['desc'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddArticleScreen(
                                      articleId: articleDoc.id,
                                      initialData: articleData,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Hapus Artikel"),
                                    content: const Text("Anda yakin ingin menghapus artikel ini?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ) ?? false;

                                if (confirm) {
                                  await FirebaseFirestore.instance.collection('articles').doc(articleDoc.id).delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class DonutChart extends StatelessWidget {
  final double users;
  final double doctors;
  final double clinics;

  const DonutChart({
    super.key,
    required this.users,
    required this.doctors,
    required this.clinics,
  });

  @override
  Widget build(BuildContext context) {
    final total = users + doctors + clinics;
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(110, 110),
                  painter: DonutChartPainter(
                    users: users,
                    doctors: doctors,
                    clinics: clinics,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toInt().toString(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(
                      "Total Aset",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem("User", users, Colors.blue, total),
                const SizedBox(height: 8),
                _buildLegendItem("Dokter", doctors, Colors.teal, total),
                const SizedBox(height: 8),
                _buildLegendItem("Klinik", clinics, Colors.orange, total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double val, Color color, double total) {
    final pct = total > 0 ? (val / total * 100).toStringAsFixed(1) : "0";
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text("${val.toInt()} ($pct%)", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double users;
  final double doctors;
  final double clinics;

  DonutChartPainter({
    required this.users,
    required this.doctors,
    required this.clinics,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = users + doctors + clinics;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -1.5708; // Start at top (-90 degrees)

    // Draw Users (Blue)
    if (users > 0) {
      final sweepAngle = (users / total) * 6.28318;
      paint.color = Colors.blue;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.05, false, paint);
      startAngle += sweepAngle;
    }

    // Draw Doctors (Teal)
    if (doctors > 0) {
      final sweepAngle = (doctors / total) * 6.28318;
      paint.color = Colors.teal;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.05, false, paint);
      startAngle += sweepAngle;
    }

    // Draw Clinics (Orange)
    if (clinics > 0) {
      final sweepAngle = (clinics / total) * 6.28318;
      paint.color = Colors.orange;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.05, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.users != users || oldDelegate.doctors != doctors || oldDelegate.clinics != clinics;
  }
}
