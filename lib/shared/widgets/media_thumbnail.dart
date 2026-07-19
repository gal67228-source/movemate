import 'dart:io';

import 'package:flutter/material.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.uri,
    this.size = 72,
    this.borderRadius = 12,
  });

  final String? uri;
  final double size;
  final double borderRadius;

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = uri;
    if (value == null || value.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.photo_outlined),
      );
    }
    final image = value.startsWith('http://') || value.startsWith('https://')
        ? Image.network(
            value,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(context),
          )
        : Image.file(
            File(value),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(context),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}
