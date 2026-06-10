import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> userData, String userId) {
    final name = userData['name'] ?? 'Pengguna';
    final email = userData['email'] ?? '-';
    final phone = userData['phone'] ?? '-';
    final address = userData['address'] ?? '-';
    final profilePic = userData['profilePic'] ?? '';

    String initials = "U";
    if (name.isNotEmpty) {
      final words = name.trim().split(' ');
      initials = words.length > 1
          ? (words[0][0] + words[1][0]).toUpperCase()
          : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Profile Header Info
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                      child: profilePic.isEmpty
                          ? Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Center(
                    child: Text(email, style: const TextStyle(color: AppColors.darkGrey, fontSize: 13)),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info Cards
                  const Text("Detail Informasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.grey)),
                    elevation: 0,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                          title: const Text("Telepon", style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                          subtitle: Text(phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          title: const Text("Alamat", style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                          subtitle: Text(address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Pets Header
                  const Text("Hewan Peliharaan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  
                  // Subcollection Pets List
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('pets').snapshots(),
                    builder: (context, petSnap) {
                      if (petSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                      }
                      if (!petSnap.hasData || petSnap.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grey),
                          ),
                          child: const Center(
                            child: Text("Tidak ada hewan peliharaan terdaftar.", style: TextStyle(color: AppColors.darkGrey, fontSize: 13)),
                          ),
                        );
                      }
                      
                      return Column(
                        children: petSnap.data!.docs.map((doc) {
                          final pet = doc.data() as Map<String, dynamic>;
                          final petName = pet['name'] ?? 'Peliharaan';
                          final petType = pet['type'] ?? '-';
                          final petAge = pet['age'] ?? '-';
                          final petBreed = pet['breed'] ?? '-';
                          final petPic = pet['petPic'] ?? '';
                          final gender = pet['gender'] ?? '';

                          // Emoji picker
                          String emoji = '🐾';
                          final t = petType.toLowerCase();
                          if (t.contains('kucing')) emoji = '🐱';
                          if (t.contains('anjing')) emoji = '🐶';
                          if (t.contains('kelinci')) emoji = '🐰';
                          if (t.contains('burung')) emoji = '🐦';
                          if (t.contains('hamster')) emoji = '🐹';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.grey)),
                            elevation: 0,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.secondaryOrangeLight,
                                backgroundImage: petPic.isNotEmpty ? NetworkImage(petPic) : null,
                                child: petPic.isEmpty ? Text(emoji, style: const TextStyle(fontSize: 22)) : null,
                              ),
                              title: Text(petName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text("$petType • $petBreed • $petAge", style: const TextStyle(fontSize: 12)),
                              trailing: gender.isEmpty
                                  ? null
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: gender == 'Betina' ? Colors.pink.shade50 : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: gender == 'Betina' ? Colors.pink.shade200 : Colors.blue.shade200),
                                      ),
                                      child: Text(
                                        gender == 'Betina' ? '♀ Betina' : '♂ Jantan',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: gender == 'Betina' ? Colors.pink.shade600 : Colors.blue.shade600),
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Daftar Pengguna"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari nama atau email pengguna...",
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.darkGrey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Belum ada data pengguna.", style: TextStyle(color: AppColors.darkGrey)),
                  );
                }
                
                var users = snapshot.data!.docs;
                
                // Search query filtering
                if (_searchQuery.isNotEmpty) {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || email.contains(_searchQuery);
                  }).toList();
                }
                
                if (users.isEmpty) {
                  return const Center(
                    child: Text("Tidak ada pengguna yang cocok.", style: TextStyle(color: AppColors.darkGrey)),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final data = userDoc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Pengguna';
                    final email = data['email'] ?? '-';
                    final profilePic = data['profilePic'] ?? '';
                    
                    String initials = "U";
                    if (name.isNotEmpty) {
                      final words = name.trim().split(' ');
                      initials = words.length > 1
                          ? (words[0][0] + words[1][0]).toUpperCase()
                          : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.grey)),
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                          child: profilePic.isEmpty
                              ? Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                              : null,
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(email, style: const TextStyle(color: AppColors.darkGrey, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
                        onTap: () => _showUserDetails(context, data, userDoc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
