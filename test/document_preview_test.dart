import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:wildlife_transport/core/widgets/document_preview_content_stub.dart';

void main() {
  testWidgets('PDF paths use the native PDF viewer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlatformDocumentPreview(
            uri: Uri.parse('https://example.com/uploads/invoices/invoice.pdf'),
          ),
        ),
      ),
    );

    expect(find.byType(PdfViewer), findsOneWidget);
    expect(
      find.text('This document cannot be previewed on this device.'),
      findsNothing,
    );
  });

  testWidgets('file API image URLs use the native image preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlatformDocumentPreview(
            uri: Uri.parse('https://example.com/file?name=driver-id-card.jpg'),
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.text('This document cannot be previewed on this device.'),
      findsNothing,
    );
  });

  testWidgets('file API PDF URLs use the native PDF viewer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlatformDocumentPreview(
            uri: Uri.parse('https://example.com/file?name=driver-licence.pdf'),
          ),
        ),
      ),
    );

    expect(find.byType(PdfViewer), findsOneWidget);
    expect(
      find.text('This document cannot be previewed on this device.'),
      findsNothing,
    );
  });
}
