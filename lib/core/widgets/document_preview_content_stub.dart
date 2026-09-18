import 'package:flutter/material.dart';

class PlatformDocumentPreview extends StatelessWidget {
  final Uri uri;

  const PlatformDocumentPreview({super.key, required this.uri});

  bool get _isImage {
    final path = uri.path.toLowerCase();
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Center(
          child: Image.network(
            uri.toString(),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, _, _) => const _PreviewError(),
          ),
        ),
      );
    }

    return const _PreviewError(
      message: 'This document cannot be previewed on this device.',
    );
  }
}

class _PreviewError extends StatelessWidget {
  final String message;

  const _PreviewError({this.message = 'Could not load this document.'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
