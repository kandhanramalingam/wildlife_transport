import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wildlife_transport/features/delivery/models/photo_meta.dart';
import 'package:wildlife_transport/features/delivery/models/start_delivery_submission.dart';
import 'package:wildlife_transport/features/delivery/offline/offloading_queue_store_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'browser evidence survives reopening storage with video larger than localStorage quota',
    () async {
      final store = createOffloadingQueueStore();
      final bytes = Uint8List(6 * 1024 * 1024)..[0] = 23;
      final job = await store.enqueue(
        deliveryId: 'browser-${DateTime.now().microsecondsSinceEpoch}',
        vehicleId: 'vehicle-1',
        submission: _submission(bytes),
      );
      addTearDown(() => store.remove(job));
      final reopened = createOffloadingQueueStore();
      final restored = (await reopened.load()).singleWhere(
        (value) => value.id == job.id,
      );
      final video = await restored.submission.endAnimalVideos.photo
          .readAsBytes();
      expect(video.length, bytes.length);
      expect(video.first, 23);
      expect(restored.submission.clientSignature, [4, 5]);
      expect(restored.submission.clientComment, 'Handle carefully');
      expect(restored.submission.endAnimalPhotos.single.lotNumber, '101');
      await reopened.remove(restored);
      expect(
        (await store.load()).where((value) => value.id == job.id),
        isEmpty,
      );
    },
    skip: !kIsWeb,
  );

  test(
    'concurrent browser saves and acknowledgement preserve the other jobs',
    () async {
      final store = createOffloadingQueueStore();
      final prefix =
          'browser-concurrent-${DateTime.now().microsecondsSinceEpoch}';
      final jobs = await Future.wait([
        for (var index = 0; index < 3; index++)
          store.enqueue(
            deliveryId: '$prefix-$index',
            vehicleId: null,
            submission: _submission(Uint8List.fromList([1, 2, 3])),
          ),
      ]);
      addTearDown(() async {
        for (final job in (await store.load()).where(
          (value) => value.deliveryId.startsWith(prefix),
        )) {
          await store.remove(job);
        }
      });
      await Future.wait([
        store.remove(jobs.first),
        createOffloadingQueueStore().enqueue(
          deliveryId: '$prefix-new',
          vehicleId: null,
          submission: _submission(Uint8List.fromList([9])),
        ),
      ]);
      final restored = (await createOffloadingQueueStore().load()).where(
        (value) => value.deliveryId.startsWith(prefix),
      );
      expect(
        restored.map((job) => job.deliveryId),
        unorderedEquals(['$prefix-1', '$prefix-2', '$prefix-new']),
      );
    },
    skip: !kIsWeb,
  );
}

CompleteOffloadingSubmission _submission(Uint8List video) {
  PhotoMeta media(String name, Uint8List bytes) => PhotoMeta(
    photo: XFile.fromData(bytes, name: name),
    dateTime: DateTime.utc(2026, 10, 12),
    latitude: -24.29,
    longitude: 28.12,
    lotNumber: '101',
  );
  return CompleteOffloadingSubmission(
    endAnimalPhotos: [
      media('animals.jpg', Uint8List.fromList([1, 2])),
    ],
    endAnimalVideos: media('animals.mp4', video),
    clientSignature: Uint8List.fromList([4, 5]),
    endOdometerReading: 1200,
    buyerId: 'buyer-1',
    clientComment: 'Handle carefully',
    offLoadChecklist: const [
      DeliveryChecklistItem(item: 'Animals checked', checked: true),
    ],
  );
}
