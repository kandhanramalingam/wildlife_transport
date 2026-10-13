import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PlatformDocumentPreview extends StatelessWidget {
  final Uri uri;

  const PlatformDocumentPreview({super.key, required this.uri});

  String get _documentName =>
      (uri.queryParameters['name'] ?? uri.path).toLowerCase();

  bool get _isImage {
    return _documentName.endsWith('.png') ||
        _documentName.endsWith('.jpg') ||
        _documentName.endsWith('.jpeg') ||
        _documentName.endsWith('.gif') ||
        _documentName.endsWith('.webp');
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

    if (_documentName.endsWith('.pdf')) {
      return PdfViewer.uri(
        uri,
        params: PdfViewerParams(
          errorBannerBuilder: (context, error, stackTrace, documentRef) =>
              const _PreviewError(message: 'Could not load this PDF.'),
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
