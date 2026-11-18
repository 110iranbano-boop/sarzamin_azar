import 'package:flutter/material.dart';

class SafeImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color fallbackColor;
  final IconData fallbackIcon;

  const SafeImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackColor = const Color(0xFF1E1E2C),
    this.fallbackIcon = Icons.image_not_supported,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.trim().isEmpty) return _buildFallback();

    return Image.asset(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: fallbackColor,
      child: Center(
        child: Icon(fallbackIcon, color: Colors.white30, size: 50),
      ),
    );
  }
}