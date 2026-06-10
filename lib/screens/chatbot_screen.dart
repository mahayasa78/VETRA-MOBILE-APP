import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemini_service.dart';
import '../utils/app_colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Each message: { sender, text, imageBase64? }
  List<Map<String, dynamic>> messages = [];
  bool _isTyping = false;
  Uint8List? _pendingImage;

  String get _storageKey => 'vetra_ai_chat_history_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          messages = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
        _scrollToBottom();
        return;
      } catch (_) {}
    }
    // First time — show welcome message
    setState(() {
      messages.add({
        "sender": "bot",
        "text":
            "Halo! 👋 Saya VETRA, asisten kesehatan hewan peliharaanmu. Kamu bisa bertanya atau kirimkan foto hewan peliharaanmu untuk saya analisis! 🐾",
      });
    });
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Only save text messages (skip imageBytes which can't be serialized easily)
    final saveable = messages.map((m) {
      return {
        'sender': m['sender'],
        'text': m['text'] ?? '',
      };
    }).toList();
    await prefs.setString(_storageKey, jsonEncode(saveable));
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Riwayat Chat?"),
        content: const Text(
            "Semua percakapan dengan VETRA AI akan dihapus. Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      setState(() {
        messages = [
          {
            "sender": "bot",
            "text":
                "Halo! 👋 Saya VETRA, asisten kesehatan hewan peliharaanmu. Kamu bisa bertanya atau kirimkan foto hewan peliharaanmu untuk saya analisis! 🐾",
          }
        ];
      });
      _saveHistory();
    }
  }

  Future<void> _deleteMessage(int index) async {
    setState(() {
      messages.removeAt(index);
    });
    _saveHistory();
  }

  // ─── Image ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1024);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _pendingImage = bytes);
  }

  // ─── Send ────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    final imageToSend = _pendingImage;
    _controller.clear();
    setState(() {
      messages.add({
        "sender": "user",
        "text": text,
        if (imageToSend != null) "imageBytes": imageToSend,
      });
      _pendingImage = null;
      _isTyping = true;
    });
    _scrollToBottom();

    String response;
    if (imageToSend != null) {
      response =
          await GeminiService.sendMessageWithImage(text, imageToSend);
    } else {
      response = await GeminiService.sendMessage(text);
    }

    // Clean up markdown symbols from AI response
    final cleanedResponse = _cleanMarkdown(response);

    setState(() {
      messages.add({"sender": "bot", "text": cleanedResponse});
      _isTyping = false;
    });
    _scrollToBottom();
    _saveHistory();
  }

  // ─── Markdown Cleaner ────────────────────────────────────────────────────────

  /// Converts Gemini markdown to plain readable text.
  String _cleanMarkdown(String text) {
    // Remove bold (**text** or __text__)
    text = text.replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(
        RegExp(r'__(.+?)__'), (m) => m.group(1) ?? '');
    // Remove italic (*text* or _text_) — single asterisk/underscore
    text = text.replaceAllMapped(
        RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
        (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(
        RegExp(r'(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'), (m) => m.group(1) ?? '');
    // Remove headers (## Heading)
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Remove horizontal rules
    text = text.replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '');
    // Remove inline code backticks
    text = text.replaceAllMapped(
        RegExp(r'`(.+?)`'), (m) => m.group(1) ?? '');
    // Remove code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    // Trim extra blank lines (more than 2 consecutive newlines → 2)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  // ─── Scroll ──────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Bubble ──────────────────────────────────────────────────────────────────

  Widget _chatBubble(Map<String, dynamic> msg, int index) {
    final isUser = msg['sender'] == 'user';
    final text = msg['text'] as String? ?? '';
    final imageBytes = msg['imageBytes'] as Uint8List?;

    return GestureDetector(
      onLongPress: () => _showDeleteMessageDialog(index),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageBytes != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Image.memory(imageBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180),
                ),
              if (text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                )
              else if (imageBytes != null)
                const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteMessageDialog(int index) {
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
              title: const Text("Hapus pesan ini",
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.red),
              title: const Text("Hapus semua riwayat chat",
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _clearHistory();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("VETRA AI",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text("Asisten Kesehatan Hewan",
                  style:
                      TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined,
                color: Colors.white),
            tooltip: "Hapus riwayat chat",
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isTyping) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius:
                                  BorderRadius.circular(16)),
                          child: Row(children: [
                            SizedBox(
                                width: 30,
                                height: 14,
                                child: const _TypingDots()),
                            const SizedBox(width: 8),
                            Text(
                              "VETRA sedang mengetik...",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  );
                }
                return _chatBubble(messages[index], index);
              },
            ),
          ),

          // Pending image preview
          if (_pendingImage != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              color: Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_pendingImage!,
                        width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text("Gambar siap dikirim",
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.darkGrey))),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.red),
                    onPressed: () =>
                        setState(() => _pendingImage = null),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image_outlined,
                        color: _isTyping
                            ? Colors.grey
                            : AppColors.primary),
                    onPressed: _isTyping ? null : _pickImage,
                    tooltip: "Kirim gambar",
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Tanya sesuatu tentang hewan...",
                        hintStyle:
                            const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isTyping ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? Colors.grey
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Typing Dots ─────────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final opacity =
                ((_controller.value * 3 - i).clamp(0.0, 1.0));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade500.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
