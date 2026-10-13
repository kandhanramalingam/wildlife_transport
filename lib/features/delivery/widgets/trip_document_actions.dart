import 'package:flutter/material.dart';

import '../../../core/config/environment.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/document_preview.dart';

/// Consistent access to the paperwork attached to a trip.
class TripDocumentActions extends StatelessWidget {
  final String? invoicePath;
  final List<String> permits;
  final List<String> maps;
  final bool showHeading;

  const TripDocumentActions({
    super.key,
    this.invoicePath,
    this.permits = const [],
    this.maps = const [],
    this.showHeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading) ...[
          const Text(
            'Trip documents',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DocumentButton(
              label: 'Invoice',
              tooltip: 'View invoice PDF',
              icon: Icons.receipt_long_outlined,
              available: invoicePath?.trim().isNotEmpty == true,
              onPressed: () => _openSingle(
                context,
                invoicePath,
                type: 'invoice',
                fallbackTitle: 'Invoice',
              ),
            ),
            _DocumentButton(
              label: 'Permits (${permits.length})',
              tooltip: 'View permits',
              icon: Icons.description_outlined,
              available: permits.isNotEmpty,
              onPressed: () => _openList(
                context,
                permits,
                type: 'permit',
                fallbackTitle: 'Permit',
              ),
            ),
            _DocumentButton(
              label: maps.length > 1 ? 'Maps (${maps.length})' : 'Map',
              tooltip: 'View map',
              icon: Icons.map_outlined,
              available: maps.isNotEmpty,
              onPressed: () =>
                  _openList(context, maps, type: 'map', fallbackTitle: 'Map'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openSingle(
    BuildContext context,
    String? rawPath, {
    required String type,
    required String fallbackTitle,
  }) async {
    final path = rawPath?.trim() ?? '';
    if (path.isEmpty) {
      _showUnavailable(context, type);
      return;
    }
    await _openDocument(context, path, fallbackTitle, type);
  }

  Future<void> _openList(
    BuildContext context,
    List<String> paths, {
    required String type,
    required String fallbackTitle,
  }) async {
    final available = paths.where((path) => path.trim().isNotEmpty).toList();
    if (available.isEmpty) {
      _showUnavailable(context, type);
      return;
    }
    var selected = available.first;
    if (available.length > 1) {
      final picked = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (_, index) => ListTile(
              leading: Icon(
                type == 'map' ? Icons.map_outlined : Icons.description_outlined,
              ),
              title: Text('$fallbackTitle ${index + 1}'),
              onTap: () => Navigator.pop(sheetContext, available[index]),
            ),
          ),
        ),
      );
      if (picked == null || !context.mounted) return;
      selected = picked;
    }
    await _openDocument(context, selected, fallbackTitle, type);
  }

  Future<void> _openDocument(
    BuildContext context,
    String path,
    String fallbackTitle,
    String type,
  ) async {
    try {
      await showDocumentPreview(
        context,
        title: fallbackTitle,
        uri: resolveTripDocumentUri(Environment.apiBaseUrl, path),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the $type file.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUnavailable(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No ${type == 'map' ? 'map' : type} is available for this trip.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DocumentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String tooltip;
  final bool available;
  final VoidCallback onPressed;

  const _DocumentButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.available,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: available ? AppTheme.primary : AppTheme.textSecondary,
      ),
      label: Text(label),
      tooltip: available ? tooltip : '$label unavailable',
      onPressed: onPressed,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: available
            ? AppTheme.primary.withValues(alpha: 0.35)
            : const Color(0xFFD7D7D7),
      ),
      labelStyle: TextStyle(
        color: available ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

Uri resolveTripDocumentUri(String apiBaseUrl, String documentPath) {
  final trimmedPath = documentPath.trim();
  final parsedPath = Uri.tryParse(trimmedPath);
  if (parsedPath != null && parsedPath.hasScheme) return parsedPath;
  return Uri.parse(apiBaseUrl).resolve(trimmedPath.replaceAll('\\', '/'));
}
