import 'package:flutter/material.dart';

class MenuImage extends StatelessWidget {
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit fit;

  const MenuImage({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  String _resolveAssetPath(String path) {
    if (path.startsWith('assets/images/')) {
      return path.replaceFirst('assets/', '');
    }
    if (path.startsWith('assets/')) {
      final rest = path.replaceFirst('assets/', '');
      if (rest.startsWith('images/')) {
        return rest;
      }
      return 'images/$rest';
    }
    if (path.startsWith('images/')) {
      return path;
    }
    return 'images/$path';
  }

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade100,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade100,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.deepOrange,
              ),
            ),
          );
        },
      );
    } else {
      final resolvedPath = _resolveAssetPath(imagePath);
      return Image.asset(
        resolvedPath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade100,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }
}

