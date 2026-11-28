import 'package:flutter/material.dart';

class ReviveAvatar extends StatelessWidget {
  const ReviveAvatar({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF39215B),
        foregroundImage: url.isEmpty ? null : NetworkImage(url),
        onForegroundImageError: url.isEmpty ? null : (_, _) {},
        child: Icon(
          Icons.person,
          color: const Color(0xFFE0CBFF),
          size: size * .55,
        ),
      );
}
