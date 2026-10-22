import 'package:flutter/material.dart';

class TiffinLogo extends StatelessWidget {
  final double size;
  final bool withGlow;
  final bool circular;

  const TiffinLogo({
    Key? key,
    this.size = 48,
    this.withGlow = true,
    this.circular = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(circular ? size / 2 : 12),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Beautiful fallback styled icon if asset is not bundled
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: size * 0.55,
            ),
          );
        },
      ),
    );

    if (!withGlow) {
      return imageWidget;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.35),
            blurRadius: size * 0.25,
            spreadRadius: 1,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: imageWidget,
    );
  }
}
