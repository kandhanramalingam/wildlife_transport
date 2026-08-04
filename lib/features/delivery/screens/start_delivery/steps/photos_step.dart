import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../models/photo_meta.dart';
import '../widgets/photo_viewer_screen.dart';

class PhotosStepData {
  final int? odometerReading;
  final List<XFile> vehiclePhotos;
  final List<XFile> animalPhotos;
  final XFile animalVideo;
  final String latitude;
  final String longitude;

  const PhotosStepData({
    required this.odometerReading,
    required this.vehiclePhotos,
    required this.animalPhotos,
    required this.animalVideo,
    required this.latitude,
    required this.longitude,
  });
}

class PhotosStep extends StatefulWidget {
  final ValueChanged<PhotosStepData> onNext;
  final bool includeVehicleDetails;
  final bool includeVehiclePhotos;
  final bool isOffLoading;

  const PhotosStep({
    super.key,
    required this.onNext,
    this.includeVehicleDetails = true,
    this.includeVehiclePhotos = true,
    this.isOffLoading = false,
  });

  @override
  State<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<PhotosStep> {
  final _kmController = TextEditingController();
  final List<PhotoMeta> _vehiclePhotos = [];
  final List<PhotoMeta> _animalPhotos = [];
  final _picker = ImagePicker();
  XFile? _animalVideo;
  String? _latitude;
  String? _longitude;
  bool _isCapturing = false;

  bool get _canProceed =>
      (!widget.includeVehicleDetails ||
          (int.tryParse(_kmController.text.trim()) ?? -1) >= 0) &&
      (!widget.includeVehiclePhotos || _vehiclePhotos.isNotEmpty) &&
      _animalPhotos.isNotEmpty &&
      _animalVideo != null &&
      _latitude != null &&
      _longitude != null;

  Future<({String display, String? latitude, String? longitude})>
  _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (display: 'Location off', latitude: null, longitude: null);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (display: 'Permission denied', latitude: null, longitude: null);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final lat = pos.latitude.toStringAsFixed(5);
      final lng = pos.longitude.toStringAsFixed(5);
      return (display: '$lat°, $lng°', latitude: lat, longitude: lng);
    } catch (_) {
      return (display: 'Location unavailable', latitude: null, longitude: null);
    }
  }

  Future<void> _capturePhoto(List<PhotoMeta> list) async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo == null) return;

      setState(() => _isCapturing = true);
      final location = await _fetchLocation();

      if (mounted) {
        setState(() {
          list.add(
            PhotoMeta(
              photo: photo,
              dateTime: DateTime.now(),
              location: location.display,
            ),
          );
          if (location.latitude != null && location.longitude != null) {
            _latitude = location.latitude;
            _longitude = location.longitude;
          }
          _isCapturing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture photo')),
        );
      }
    }
  }

  Future<void> _captureVideo() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
      if (video != null && mounted) {
        setState(() => _animalVideo = video);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture video clip')),
        );
      }
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.includeVehicleDetails) ...[
                      _sectionHeader('Vehicle Details'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _kmController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Odometer Reading (KM)',
                          prefixIcon: Icon(Icons.speed_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (widget.includeVehiclePhotos) ...[
                      _sectionHeader('Vehicle Photos'),
                      const SizedBox(height: 4),
                      const Text(
                        'Capture photos of the vehicle from all sides',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _photoGrid(
                        photos: _vehiclePhotos,
                        onAdd: () => _capturePhoto(_vehiclePhotos),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _sectionHeader('Animal Photos'),
                    const SizedBox(height: 4),
                    Text(
                      widget.isOffLoading
                          ? 'Take photos of all animals on the truck before off-loading'
                          : 'Capture photos of the animals before transport',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _photoGrid(
                      photos: _animalPhotos,
                      onAdd: () => _capturePhoto(_animalPhotos),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Animal Video Clip'),
                    const SizedBox(height: 4),
                    Text(
                      widget.isOffLoading
                          ? 'Record a video clip while the animals are being off-loaded (up to 30 seconds)'
                          : 'Capture a video clip of the animals before transport (up to 30 seconds)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _videoCaptureCard(),
                  ],
                ),
              ),
            ),
            _buildNextButton(),
          ],
        ),
        if (_isCapturing) _buildCapturingOverlay(),
      ],
    );
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary,
    ),
  );

  Widget _photoGrid({
    required List<PhotoMeta> photos,
    required VoidCallback onAdd,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...photos.asMap().entries.map(
          (e) => _thumbnail(photos: photos, index: e.key),
        ),
        _addButton(onAdd),
      ],
    );
  }

  Widget _thumbnail({required List<PhotoMeta> photos, required int index}) {
    final meta = photos[index];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoViewerScreen(
            photos: photos,
            initialIndex: index,
            onDelete: (i) => setState(() => photos.removeAt(i)),
          ),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    meta.photo.path,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(meta.photo.path),
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
          ),
          // Datetime + location stamp overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Text(
                _shortDateTime(meta.dateTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppTheme.textSecondary,
              size: 26,
            ),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoCaptureCard() {
    final video = _animalVideo;
    if (video == null) {
      return GestureDetector(
        onTap: _captureVideo,
        child: Container(
          width: 140,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_outlined,
                color: AppTheme.textSecondary,
                size: 30,
              ),
              SizedBox(height: 4),
              Text(
                'Record clip',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primary, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              video.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Record again',
            onPressed: _captureVideo,
            icon: const Icon(Icons.replay_outlined),
          ),
          IconButton(
            tooltip: 'Remove video',
            onPressed: () => setState(() => _animalVideo = null),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _canProceed
              ? () => widget.onNext(
                  PhotosStepData(
                    odometerReading: widget.includeVehicleDetails
                        ? int.parse(_kmController.text.trim())
                        : null,
                    vehiclePhotos: _vehiclePhotos
                        .map((meta) => meta.photo)
                        .toList(growable: false),
                    animalPhotos: _animalPhotos
                        .map((meta) => meta.photo)
                        .toList(growable: false),
                    animalVideo: _animalVideo!,
                    latitude: _latitude!,
                    longitude: _longitude!,
                  ),
                )
              : null,
          child: const Text('Next'),
        ),
      ),
    );
  }

  Widget _buildCapturingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Getting location...',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }
}
