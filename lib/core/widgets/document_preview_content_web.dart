import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class PlatformDocumentPreview extends StatefulWidget {
  final Uri uri;

  const PlatformDocumentPreview({super.key, required this.uri});

  @override
  State<PlatformDocumentPreview> createState() =>
      _PlatformDocumentPreviewState();
}

class _PlatformDocumentPreviewState extends State<PlatformDocumentPreview> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'document-preview-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      return web.HTMLIFrameElement()
        ..src = widget.uri.toString()
        ..title = 'Document preview'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0';
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
