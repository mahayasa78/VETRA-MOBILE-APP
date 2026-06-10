import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import 'chat_screen.dart';
import 'booking_screen.dart';
import 'article_detail_screen.dart';

class VetraSearchDelegate extends SearchDelegate {
  final Future<List<Map<String, dynamic>>> searchDataFuture;

  VetraSearchDelegate(this.searchDataFuture) : super(
    searchFieldLabel: "Cari dokter, klinik, artikel...",
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.white),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text(
          "Ketik sesuatu untuk mencari...",
          style: TextStyle(color: AppColors.darkGrey),
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: searchDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Terjadi kesalahan saat mencari."));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data."));
        }

        final allData = snapshot.data!;
        final q = query.toLowerCase().trim();

        final filtered = allData.where((item) {
          final title = (item['title'] ?? '').toString().toLowerCase();
          final subtitle = (item['subtitle'] ?? '').toString().toLowerCase();
          return title.contains(q) || subtitle.contains(q);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              "Tidak ada hasil yang cocok.",
              style: TextStyle(color: AppColors.darkGrey),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            final type = item['type'];
            
            IconData iconData = Icons.person;
            if (type == 'klinik') iconData = Icons.local_hospital;
            if (type == 'artikel') iconData = Icons.article;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                backgroundImage: item['profilePic'] != null ? NetworkImage(item['profilePic']) : null,
                child: item['profilePic'] == null 
                  ? Icon(iconData, color: AppColors.primary)
                  : null,
              ),
              title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['subtitle'] ?? ''),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grey),
              onTap: () {
                _navigateToResult(context, item);
              },
            );
          },
        );
      },
    );
  }

  void _navigateToResult(BuildContext context, Map<String, dynamic> item) {
    final type = item['type'];
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (type == 'dokter') {
      if (currentUser == null) return;
      final chatId = '${currentUser.uid}_${item['id']}';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            receiverId: item['id'],
            receiverName: item['title'],
          ),
        ),
      );
    } else if (type == 'klinik') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookingScreen()),
      );
    } else if (type == 'artikel') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(
            title: item['title'],
            content: item['subtitle'], // The full description is stored here or we can just fetch it
          ),
        ),
      );
    }
  }
}
