import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/widgets/loading_media_sheet.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_schedule_dto.dart';

void main() {
  test('combined customer loading media reaches the parent trip', () {
    final dto = DeliveryScheduleDto.fromJson({
      '_id': 'parent',
      'scheduleDate': '2026-10-13T10:00:00Z',
      'startAnimalPhotos': ['uploads/parent.jpg'],
      'combinedLotDeliveries': [
        {
          '_id': 'child',
          'buyerId': 'buyer-2',
          'startAnimalPhotos': ['uploads/child.jpg'],
          'startMediaMetadata': [
            {
              'kind': 'animal_photo',
              'lotNumber': '7',
              'filePath': 'uploads/child.jpg',
            },
          ],
          'lots': [
            {'lotNo': '7', 'comment': 'Keep separate'},
          ],
        },
      ],
    });
    expect(dto.startAnimalPhotos, ['uploads/parent.jpg', 'uploads/child.jpg']);
    expect(dto.startMediaMetadata.single.lotNumber, '7');
    expect(dto.lotDetails.single.comment, 'Keep separate');
  });

  testWidgets('shows selected legacy lot images alongside trip media', (
    tester,
  ) async {
    final delivery = DeliveryModel(
      id: 'trip',
      dateTime: DateTime(2026, 10, 13),
      clientName: 'Client',
      clientAddress: '',
      startAnimalPhotos: const [
        'https://example.test/uploads/7.jpg',
        'https://example.test/uploads/8.jpg',
        'https://example.test/uploads/old.jpg',
      ],
      startMediaMetadata: const [
        DeliveryLoadingMedia(
          filePath: 'https://example.test/uploads/7.jpg',
          kind: 'animal_photo',
          lotNumber: '7',
        ),
        DeliveryLoadingMedia(
          filePath: 'https://example.test/uploads/8.jpg',
          kind: 'animal_photo',
          lotNumber: '8',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadingMediaSheet(delivery: delivery, lotNumber: '7'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lot 7 Loading Media'), findsOneWidget);
    expect(find.text('Animal Photos (1)'), findsOneWidget);
    expect(find.text('Trip Loading Media'), findsOneWidget);
    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map((widget) => (widget.image as NetworkImage).url)
        .toList();
    expect(images, hasLength(2));
    expect(images.any((url) => url.endsWith('/7.jpg')), isTrue);
    expect(images.any((url) => url.endsWith('/old.jpg')), isTrue);
    expect(images.any((url) => url.endsWith('/8.jpg')), isFalse);
  });
}
