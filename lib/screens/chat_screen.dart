import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';
import '../utils/app_network_image.dart';
import '../services/image_upload_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String currentUserName = "User";
  String currentUserRole = "user";

  Uint8List? _selectedImageBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUser() async {
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          currentUserName = data['name'] ?? 'User';
          currentUserRole = data['role'] ?? 'user';
        });
      }
    }
  }

  // ─── Send Message ────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;
    if (_isUploading) return;

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_selectedImageBytes != null) {
      try {
        imageUrl = await ImageUploadService.uploadImage(_selectedImageBytes!, folder: 'chat_images');
      } catch (e) {
        setState(() => _isUploading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal unggah gambar: $e')));
        }
        return;
      }
    }

    _controller.clear();
    setState(() {
      _selectedImageBytes = null;
      _isUploading = false;
    });

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    final String userId =
        currentUserRole == 'dokter' ? widget.receiverId : currentUser!.uid;
    final String doctorId =
        currentUserRole == 'dokter' ? currentUser!.uid : widget.receiverId;
    final String userName =
        currentUserRole == 'dokter' ? widget.receiverName : currentUserName;
    final String doctorName =
        currentUserRole == 'dokter' ? currentUserName : widget.receiverName;

    final String lastMsg =
        text.isNotEmpty ? text : (imageUrl != null ? '📷 Gambar' : '');

    await chatRef.set({
      'userId': userId,
      'doctorId': doctorId,
      'userName': userName,
      'doctorName': doctorName,
      'lastMessage': lastMsg,
      'lastSenderId': currentUser!.uid,
      'lastTimestamp': FieldValue.serverTimestamp(),
      if (currentUserRole == 'dokter') 'unreadUser': FieldValue.increment(1),
      if (currentUserRole != 'dokter') 'unreadDoctor': FieldValue.increment(1),
    }, SetOptions(merge: true));

    final Map<String, dynamic> msgData = {
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'type': imageUrl != null ? 'image' : 'text',
      'isRead': false,
    };
    if (imageUrl != null) msgData['imageUrl'] = imageUrl;
    if (text.isNotEmpty) msgData['text'] = text;

    await chatRef.collection('messages').add(msgData);
    _scrollToBottom();
  }

  // ─── Pick Image ──────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    if (currentUser == null) return;
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memilih gambar: $e')));
      }
    }
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────

  /// Hapus satu pesan (hanya milik sendiri)
  Future<void> _deleteMessage(String messageId, String senderId) async {
    if (senderId != currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kamu hanya bisa menghapus pesanmu sendiri.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Pesan?"),
        content: const Text("Pesan ini akan dihapus secara permanen."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal")),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    }
  }

  /// Hapus semua pesan dalam chat ini
  Future<void> _deleteAllMessages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Semua Pesan?"),
        content: const Text(
            "Semua riwayat percakapan dalam chat ini akan dihapus. Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal")),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Batch delete all messages
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    final snapshot = await messagesRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    // Reset lastMessage on parent doc
    batch.update(
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId),
      {'lastMessage': '', 'lastTimestamp': FieldValue.serverTimestamp()},
    );
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua pesan berhasil dihapus.")),
      );
    }
  }

  // ─── Long-press menu ─────────────────────────────────────────────────────────

  void _showMessageOptions(
      BuildContext context, String messageId, String senderId) {
    final isMe = senderId == currentUser?.uid;
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
            if (isMe)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Hapus pesan ini",
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(messageId, senderId);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.red),
              title: const Text("Hapus semua pesan",
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteAllMessages();
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

  // ─── Scroll ──────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ─── Bubble ──────────────────────────────────────────────────────────────────

  Widget _buildBubble(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isMe = data['senderId'] == currentUser?.uid;
    final bool isImage = data['type'] == 'image';
    final String text = data['text'] ?? '';
    final String? imageUrl = data['imageUrl'];

    Timestamp? ts = data['timestamp'];
    String timeStr = "";
    if (ts != null) {
      timeStr = DateFormat('HH:mm').format(ts.toDate());
    }

    return GestureDetector(
      onLongPress: () =>
          _showMessageOptions(context, doc.id, data['senderId'] ?? ''),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft:
                  isMe ? const Radius.circular(15) : const Radius.circular(0),
              bottomRight:
                  isMe ? const Radius.circular(0) : const Radius.circular(15),
            ),
            border: isMe ? null : Border.all(color: AppColors.grey),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isImage && imageUrl != null)
                Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AppNetworkImage(
                        url: imageUrl,
                        width: 200,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(text,
                          style: TextStyle(
                              color: isMe
                                  ? AppColors.white
                                  : AppColors.black,
                              fontSize: 15)),
                    ],
                  ],
                )
              else
                Text(text,
                    style: TextStyle(
                        color: isMe ? AppColors.white : AppColors.black,
                        fontSize: 15)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr,
                      style: TextStyle(
                          color: isMe
                              ? AppColors.primaryLight
                              : AppColors.darkGrey,
                          fontSize: 10)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.done_all,
                        size: 14,
                        color: (data['isRead'] ?? false)
                            ? Colors.blue
                            : Colors.grey),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          // Tombol konsultasi — hanya untuk user (bukan dokter)
          if (currentUserRole != 'dokter')
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/consultation');
              },
              icon: const Icon(Icons.medical_services_outlined,
                  color: Colors.white, size: 18),
              label: const Text(
                "Konsultasi",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete_all') _deleteAllMessages();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined,
                        color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text("Hapus semua pesan",
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada pesan.\nKirim pesan pertama!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.darkGrey),
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                final messages = snapshot.data!.docs;

                // Mark messages as read
                if (currentUser != null) {
                  final unread = messages.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return d['senderId'] != currentUser!.uid &&
                        (d['isRead'] == false || d['isRead'] == null);
                  }).toList();

                  if (unread.isNotEmpty) {
                    final batch = FirebaseFirestore.instance.batch();
                    for (final doc in unread) {
                      batch.update(doc.reference, {'isRead': true});
                    }
                    final fieldToReset = currentUserRole == 'dokter'
                        ? 'unreadDoctor'
                        : 'unreadUser';
                    batch.update(
                      FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId),
                      {fieldToReset: 0},
                    );
                    batch.commit();
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.only(top: 10, bottom: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _buildBubble(messages[index]),
                );
              },
            ),
          ),

          // Image preview
          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: AppColors.white,
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(_selectedImageBytes!,
                        height: 100, width: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedImageBytes = null),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                  top: BorderSide(
                      color: AppColors.grey.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: AppColors.primary),
                  onPressed: _isUploading ? null : _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Tulis pesan...",
                      hintStyle:
                          const TextStyle(color: AppColors.darkGrey),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor:
                      _isUploading ? AppColors.grey : AppColors.primary,
                  radius: 22,
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send,
                              color: AppColors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
