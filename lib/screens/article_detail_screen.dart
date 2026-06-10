import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_network_image.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String imageUrl;

  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.content,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 🖼️ Sliver AppBar with image or gradient banner
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          url: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, url, err) => Container(
                            color: AppColors.primary,
                            child: const Icon(Icons.broken_image, color: Colors.white54, size: 60),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: const Icon(Icons.article, color: Colors.white24, size: 100),
                    ),
            ),
          ),

          // 📰 Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Divider(color: Colors.grey.shade200, thickness: 1.5),
                  const SizedBox(height: 12),

                  // Rich-text content parser
                  ..._parseContent(context, content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parses article content line by line and renders each block with appropriate styling
  List<Widget> _parseContent(BuildContext context, String raw) {
    final List<Widget> widgets = [];
    final lines = raw.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // # Heading 1
      if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            trimmed.substring(2),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
        ));
        widgets.add(Container(height: 2, width: 40, color: AppColors.primary, margin: const EdgeInsets.only(bottom: 8)));
        continue;
      }

      // ## Heading 2
      if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            trimmed.substring(3),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ));
        continue;
      }

      // - Bullet point
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final text = trimmed.substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, right: 10),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Plain paragraph text
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          trimmed,
          style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
        ),
      ));
    }

    return widgets;
  }
}