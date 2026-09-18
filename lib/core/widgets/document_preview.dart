import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'document_preview_content_stub.dart'
    if (dart.library.js_interop) 'document_preview_content_web.dart';

Future<void> showDocumentPreview(
  BuildContext context, {
  required String title,
  required Uri uri,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 960,
        height: MediaQuery.sizeOf(dialogContext).height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: PlatformDocumentPreview(uri: uri)),
          ],
        ),
      ),
    ),
  );
}
