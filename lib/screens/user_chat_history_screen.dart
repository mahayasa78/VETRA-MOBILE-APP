import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import 'chat_screen.dart';
import 'chatbot_screen.dart';

class UserChatHistoryScreen extends StatelessWidget {
  const UserChatHistoryScreen({super.key});

  // ─── Delete chat (hapus dokumen chat + semua pesan di subcollection) ─────────

  Future<void> _deleteChat(
      BuildContext context, String chatId, String doctorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Chat?"),
        content: Text(
            "Riwayat chat dengan $doctorName akan dihapus secara permanen."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete all messages in subcollection first
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');
    final msgs = await messagesRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }
    // Delete parent chat document
    batch.delete(
        FirebaseFirestore.instance.collection('chats').doc(chatId));
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Chat dengan $doctorName dihapus.")),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Chat"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── VETRA AI tile ──────────────────────────────────────────────────
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy,
                  color: AppColors.white, size: 28),
            ),
            title: const Text("Chatbot VETRA AI",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: const Text(
                "Tanya apa saja tentang kesehatan hewan",
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text("AI",
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatbotScreen())),
          ),
          const Divider(height: 1),

          // ── Section header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text("Konsultasi Dokter",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
              ],
            ),
          ),

          // ── Doctor chat list ───────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('userId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: const TextStyle(fontSize: 12)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text(
                            "Belum ada riwayat chat dengan dokter.",
                            style: TextStyle(color: AppColors.darkGrey, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pushNamed(context, '/consultation'),
                              child: const Text("Mulai Konsultasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Sort by lastTimestamp descending
                final chats = snapshot.data!.docs.toList();
                chats.sort((a, b) {
                  final tsA = (a.data() as Map<String, dynamic>)[
                      'lastTimestamp'] as Timestamp?;
                  final tsB = (b.data() as Map<String, dynamic>)[
                      'lastTimestamp'] as Timestamp?;
                  if (tsA == null) return 1;
                  if (tsB == null) return -1;
                  return tsB.compareTo(tsA);
                });

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final chatDoc = chats[index];
                    final data =
                        chatDoc.data() as Map<String, dynamic>;
                    final doctorName = data['doctorName'] ?? 'Dokter';
                    final lastMessage = data['lastMessage'] ?? '';
                    final doctorId = data['doctorId'];
                    final int unreadCount =
                        (data['unreadUser'] ?? 0) as int;
                    // unreadDoctor: apakah dokter sudah baca pesan terakhir dari user
                    final int unreadByDoctor =
                        (data['unreadDoctor'] ?? 0) as int;
                    final lastSenderId = data['lastSenderId'] ?? '';
                    final bool isSentByMe = lastSenderId == currentUser.uid;

                    Timestamp? ts = data['lastTimestamp'];
                    String timeStr = "";
                    if (ts != null) {
                      final dt = ts.toDate();
                      final now = DateTime.now();
                      timeStr = (dt.year == now.year &&
                              dt.month == now.month &&
                              dt.day == now.day)
                          ? DateFormat('HH:mm').format(dt)
                          : DateFormat('dd/MM').format(dt);
                    }

                    String initials = "D";
                    if (doctorName.isNotEmpty) {
                      final clean =
                          doctorName.replaceAll('drh.', '').trim();
                      final parts = clean.split(' ');
                      initials = parts.length >= 2
                          ? (parts[0][0] + parts[1][0]).toUpperCase()
                          : clean.substring(0, 1).toUpperCase();
                    }

                    return Dismissible(
                      key: Key(chatDoc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 28),
                      ),
                      confirmDismiss: (_) async {
                        await _deleteChat(
                            context, chatDoc.id, doctorName);
                        return false; // StreamBuilder handles removal
                      },
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatDoc.id,
                              receiverId: doctorId,
                              receiverName: doctorName,
                            ),
                          ),
                        ),
                        onLongPress: () => _showChatOptions(
                            context, chatDoc.id, doctorName),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(initials,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            doctorName,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: unreadCount > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: unreadCount > 0
                                                ? AppColors.primary
                                                : Colors.grey,
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Centang jika pesan terakhir dikirim oleh user ini
                                        if (isSentByMe) ...[
                                          Icon(
                                            Icons.done_all,
                                            size: 14,
                                            // Abu = dokter belum baca, Biru = dokter sudah baca
                                            color: unreadByDoctor == 0
                                                ? Colors.blue
                                                : Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Expanded(
                                          child: Text(
                                            lastMessage,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: unreadCount > 0
                                                  ? Colors.black87
                                                  : Colors.grey[600],
                                              fontWeight: unreadCount > 0
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (unreadCount > 0) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.all(5),
                                            decoration:
                                                const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              unreadCount > 99
                                                  ? "99+"
                                                  : "$unreadCount",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  void _showChatOptions(
      BuildContext context, String chatId, String doctorName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: Text("Hapus chat dengan $doctorName",
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteChat(context, chatId, doctorName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("Batal"),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
