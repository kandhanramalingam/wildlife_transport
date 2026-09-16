import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static String formatPhoneNumber(String rawNumber) {
    final clean = rawNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return '';
    var phone = clean.replaceAll('+', '');
    // If local South African number starting with 0, convert to 27...
    if (phone.startsWith('0') && phone.length == 10) {
      phone = '27${phone.substring(1)}';
    }
    return phone;
  }

  static Future<bool> launchWhatsApp({
    required BuildContext context,
    required String contactNumber,
    String? message,
  }) async {
    final phone = formatPhoneNumber(contactNumber);
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid contact phone number for WhatsApp.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    final textParam = message != null && message.trim().isNotEmpty
        ? '?text=${Uri.encodeComponent(message.trim())}'
        : '';
    final uri = Uri.parse('https://wa.me/$phone$textParam');

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp on this device.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return opened;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp on this device.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  static String composeStartLoadingMessage({
    required String clientName,
    List<String> lotNumbers = const [],
  }) {
    final lots = lotNumbers.isNotEmpty ? ' (Lots: ${lotNumbers.join(', ')})' : '';
    return 'Hello $clientName,\n\nLoading of your animals$lots has started.\n- AWA Transport Team';
  }

  static String composeLoadingCompletedMessage({
    required String clientName,
  }) {
    return 'Hello $clientName,\n\nLoading has been completed successfully. The transport vehicle is being prepared for departure.\n- AWA Transport Team';
  }

  static String composeStartTripMessage({
    required String clientName,
    String? destinationLatitude,
    String? destinationLongitude,
  }) {
    var navLink = '';
    if (destinationLatitude != null &&
        destinationLongitude != null &&
        destinationLatitude.trim().isNotEmpty &&
        destinationLongitude.trim().isNotEmpty) {
      navLink = '\n\nDestination Route: https://www.google.com/maps/dir/?api=1&destination=${destinationLatitude.trim()},${destinationLongitude.trim()}';
    }
    return 'Hello $clientName,\n\nYour delivery trip has started and our driver is on the way.$navLink\n- AWA Transport Team';
  }
}
