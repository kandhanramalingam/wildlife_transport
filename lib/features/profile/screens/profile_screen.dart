import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/environment.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../delivery/screens/trip_customers_screen.dart';
import '../models/driver_profile.dart';
import '../presentation/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppDependencies.createProfileController()
      ..addListener(_onStateChanged)
      ..load();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onStateChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final profile = _controller.profile;
    if (_controller.isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && profile == null) {
      return _ErrorState(
        message: _controller.errorMessage!,
        buttonLabel: _controller.requiresLogin ? 'Log in again' : 'Retry',
        onPressed: _controller.requiresLogin
            ? AppDependencies.sessionController.logout
            : _controller.load,
      );
    }

    if (profile == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildAvatar(profile),
            const SizedBox(height: 24),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildInfoCard(profile),
            const SizedBox(height: 16),
            _buildDetailsCard('Driver Details', [
              (Icons.badge_outlined, 'ID Number', profile.idNumber),
              (
                Icons.menu_book_outlined,
                'Passport Number',
                profile.passportNumber,
              ),
              (Icons.verified_user_outlined, 'Status', profile.status),
              (Icons.person_outline, 'Driver Type', profile.type),
            ]),
            const SizedBox(height: 16),
            _buildDetailsCard('Licence Details', [
              (
                Icons.credit_card_outlined,
                'Licence Number',
                profile.licenceNumber,
              ),
              (Icons.category_outlined, 'Licence Code', profile.licenceCode),
              (
                Icons.event_outlined,
                'Licence Expiry',
                _formatDate(profile.licenceExpiry),
              ),
            ]),
            const SizedBox(height: 16),
            _buildDocumentsCard(profile),
            const SizedBox(height: 16),
            _buildVehicleCard(profile.vehicle),
            const SizedBox(height: 16),
            _buildDetailsCard('Allocation Details', [
              (
                Icons.event_available_outlined,
                'Start Date',
                _formatDate(profile.allocationStartDate),
              ),
              (
                Icons.event_busy_outlined,
                'End Date',
                _formatDate(profile.allocationEndDate),
              ),
              (
                Icons.route_outlined,
                'Vehicle Combination',
                profile.vehicleCombination == null
                    ? 'Not assigned'
                    : 'Assigned',
              ),
            ]),
            const SizedBox(height: 24),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(DriverProfile profile) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary,
          ),
          child: const Icon(Icons.person, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          profile.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${profile.id}',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoCard(DriverProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Info',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.phone_android,
              'Mobile',
              _valueOrDash(profile.phone),
            ),
            const Divider(height: 20),
            _infoRow(
              Icons.location_on_outlined,
              'Address',
              _valueOrDash(profile.address),
            ),
            const Divider(height: 20),
            _infoRow(
              Icons.badge_outlined,
              'Vehicle',
              _valueOrDash(profile.vehicle?.registrationNumber),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Summary",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _statItem('0', 'Assigned')),
                Expanded(child: _statItem('0', 'Completed')),
                Expanded(child: _statItem('0', 'Pending')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(DriverVehicle? vehicle) {
    return _buildDetailsCard('Vehicle Details', [
      (Icons.local_shipping_outlined, 'Make', vehicle?.make),
      (Icons.description_outlined, 'Description', vehicle?.description),
      (
        Icons.confirmation_number_outlined,
        'Registration Number',
        vehicle?.registrationNumber,
      ),
      (Icons.tag_outlined, 'Vehicle Code', vehicle?.code),
      (Icons.category_outlined, 'Vehicle Type', vehicle?.type),
      (Icons.calendar_today_outlined, 'Year', vehicle?.year?.toString()),
      (
        Icons.inventory_2_outlined,
        'Compartments',
        vehicle?.compartmentNumber?.toString(),
      ),
      (Icons.credit_card_outlined, 'Licence Code', vehicle?.licenceCode),
      (Icons.payments_outlined, 'Rate', vehicle?.rate?.toString()),
      (
        Icons.toggle_on_outlined,
        'Active',
        vehicle?.active == null ? null : (vehicle!.active! ? 'Yes' : 'No'),
      ),
    ]);
  }

  Widget _buildDetailsCard(
    String title,
    List<(IconData, String, String?)> details,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < details.length; index++) ...[
              _infoRow(
                details[index].$1,
                details[index].$2,
                _valueOrDash(details[index].$3),
              ),
              if (index < details.length - 1) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsCard(DriverProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identification & Documents',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _documentRow(
              icon: Icons.badge_outlined,
              label: 'ID Document',
              identifier: profile.idNumber ?? profile.passportNumber,
              path: profile.idPath,
            ),
            const Divider(height: 20),
            _documentRow(
              icon: Icons.credit_card_outlined,
              label: "Driver's Licence",
              identifier: profile.licenceNumber,
              path: profile.licencePath,
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentRow({
    required IconData icon,
    required String label,
    String? identifier,
    String? path,
  }) {
    final hasDocument = path != null && path.trim().isNotEmpty;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                identifier != null && identifier.trim().isNotEmpty
                    ? identifier
                    : (hasDocument ? 'Document available' : 'Not uploaded'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasDocument
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (hasDocument)
          ElevatedButton.icon(
            onPressed: () => _openDocument(path),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('View', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Missing',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }

  Future<void> _openDocument(String path) async {
    try {
      final uri = resolveInvoiceUri(Environment.apiBaseUrl, path);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open document.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open document.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Logout',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  String _valueOrDash(String? value) {
    return value == null || value.trim().isEmpty ? '-' : value;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await AppDependencies.sessionController.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  const _ErrorState({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
