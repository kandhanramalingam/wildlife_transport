import 'package:image_picker/image_picker.dart';

class PhotoMeta {
  final XFile photo;
  final DateTime dateTime;
  final String location;

  PhotoMeta({
    required this.photo,
    required this.dateTime,
    required this.location,
  });
}
