import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import 'chat_screen.dart';

class DoctorChatHistoryScreen extends StatelessWidget {
  const DoctorChatHistoryScreen({super.key});

  // ─── Delete chat ─────────────────────────────────────────────────────────────

  Future<void> _deleteChat(
      BuildContext context, String chatId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Chat?"),
        content: Text(
            "Riwayat chat dengan $userName akan dihapus secara permanen."),
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
    batch.delete(
        FirebaseFirestore.instance.collection('chats').doc(chatId));
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Chat dengan $userName dihapus.")),
      );
    }
  }

  void _showChatOptions(
      BuildContext context, String chatId, String userName) {
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
              title: Text("Hapus chat dengan $userName",
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteChat(context, chatId, userName);
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

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Silakan login"));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Pesan Masuk"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('doctorId', isEqualTo: currentUser.uid)
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text("Belum ada pesan masuk dari pasien.",
                      style: TextStyle(color: AppColors.darkGrey)),
                ],
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
              final data = chatDoc.data() as Map<String, dynamic>;
              final userName = data['userName'] ?? 'Pasien';
              final lastMessage = data['lastMessage'] ?? '';
              final userId = data['userId'];
              final int unreadCount =
                  (data['unreadDoctor'] ?? 0) as int;
              // unreadUser: apakah user sudah baca pesan terakhir dari dokter
              final int unreadByUser =
                  (data['unreadUser'] ?? 0) as int;
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

              String initials = "P";
              if (userName.isNotEmpty) {
                initials = userName.substring(0, 1).toUpperCase();
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
                  await _deleteChat(context, chatDoc.id, userName);
                  return false;
                },
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatDoc.id,
                        receiverId: userId,
                        receiverName: userName,
                      ),
                    ),
                  ),
                  onLongPress: () =>
                      _showChatOptions(context, chatDoc.id, userName),
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
                                      userName,
                                      overflow: TextOverflow.ellipsis,
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
                                  // Centang jika pesan terakhir dikirim oleh dokter ini
                                  if (isSentByMe) ...[
                                    Icon(
                                      Icons.done_all,
                                      size: 14,
                                      // Abu = user belum baca, Biru = user sudah baca
                                      color: unreadByUser == 0
                                          ? Colors.blue
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
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
    );
  }
}
