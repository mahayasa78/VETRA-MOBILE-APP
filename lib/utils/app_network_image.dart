import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Header yang diperlukan agar ImgBB tidak memblokir request gambar.
const Map<String, String> kImgbbHeaders = {
  'Referer': 'https://imgbb.com/',
  'User-Agent':
      'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/91.0.4472.120',
};

/// Helper untuk membungkus URL ImgBB dengan proxy wsrv.nl guna melewati pemblokiran ISP di Indonesia.
String _wrapUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.contains('i.ibb.co') || trimmed.contains('imgbb.com')) {
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(trimmed)}';
  }
  return trimmed;
}

/// Widget gambar dari URL (ImgBB / URL lain) dengan header yang benar.
/// Gunakan ini sebagai pengganti [Image.network] untuk semua URL gambar.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _wrapUrl(url),
      httpHeaders: kImgbbHeaders,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder ??
          (context, url) => Container(
                width: width,
                height: height,
                color: Colors.grey.shade100,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      errorWidget: errorWidget ??
          (context, url, error) => Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child:
                    const Icon(Icons.broken_image, color: Colors.grey, size: 28),
              ),
    );
  }
}

/// Versi [ImageProvider] dari [CachedNetworkImageProvider] dengan Referer header.
/// Digunakan untuk [CircleAvatar.backgroundImage] dll.
CachedNetworkImageProvider appNetworkImageProvider(String url) {
  return CachedNetworkImageProvider(
    _wrapUrl(url),
    headers: kImgbbHeaders,
  );
}
