import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wildlife_transport/core/connectivity/connectivity_monitor.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_remote_data_source.dart';
import 'package:wildlife_transport/features/delivery/data/delivery_repository_impl.dart';
import 'package:wildlife_transport/features/delivery/models/photo_meta.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/models/start_delivery_submission.dart';
import 'package:wildlife_transport/features/delivery/offline/offloading_queue_store_io.dart';
import 'package:wildlife_transport/features/delivery/offline/offloading_sync_service.dart';
import 'package:wildlife_transport/features/delivery/offline/delivery_status_queue_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (serverStatus, failureStage) in [
    for (final status in ['in_delivery', 'offloading_started'])
      for (final stage in ['none', 'video', 'completionAck']) (status, stage),
  ]) {
    test(
      'offline deliveries sync from $serverStatus after relaunch with $failureStage interruption',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'full-delivery-offline-',
        );
        const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(pathChannel, (_) async => root.path);
        FlutterSecureStorage.setMockInitialValues({});
        addTearDown(() async {
          messenger.setMockMethodCallHandler(pathChannel, null);
          await root.delete(recursive: true);
        });
        final connectivity = _OfflineConnectivity();
        final states = {'delivery-1': serverStatus, 'delivery-2': serverStatus};
        final acceptedEvidence = <String, Map<String, dynamic>>{};
        final requests = <String>[];
        var interruptOnce = failureStage != 'none';
        final dio = Dio(BaseOptions(baseUrl: 'https://transport.test/'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (!connectivity.connected) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              requests.add(options.path);
              if (options.data is FormData) {
                final file = (options.data as FormData).files.single.value;
                if (failureStage == 'video' &&
                    interruptOnce &&
                    options.path == 'file/upload-video') {
                  interruptOnce = false;
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      type: DioExceptionType.connectionError,
                    ),
                  );
                  return;
                }
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {'filePath': 'uploads/${file.filename}'},
                  ),
                );
                return;
              }
              final deliveryId = options.path.split('/')[2];
              if (options.path.endsWith('/status')) {
                final body = options.data as Map;
                expect(body['offlineReplay'], isTrue);
                expect(body['vehicleId'], 'vehicle-1');
                final status = body['status'] as String;
                if (states[deliveryId] != 'offloading_started') {
                  states[deliveryId] = status;
                }
                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 200),
                );
                return;
              }
              acceptedEvidence[deliveryId] = Map<String, dynamic>.from(
                options.data as Map,
              );
              states[deliveryId] = 'completed';
              if (failureStage == 'completionAck' && interruptOnce) {
                interruptOnce = false;
                // The server committed, but the phone lost its acknowledgement.
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.receiveTimeout,
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    '_id': deliveryId,
                    'buyerId': 'buyer-1',
                    'buyerName': 'Offline customer',
                    'scheduleDate': '2026-10-11T08:00:00.000Z',
                    'deliveryStatus': states[deliveryId],
                    'vehicleLotTotal': 3,
                    'totalLots': 3,
                    'deliveredLots': 3,
                    'balanceLots': 0,
                    'partialDelivery': false,
                  },
                ),
              );
            },
          ),
        );
        final repository = DeliveryRepositoryImpl(
          DioDeliveryRemoteDataSource(dio),
        );
        PhotoMeta media(String name) => PhotoMeta(
          photo: XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: name,
            path: name,
          ),
          dateTime: DateTime.utc(2026, 10, 11, 8),
          latitude: -24.29,
          longitude: 28.12,
        );
        final evidence = CompleteOffloadingSubmission(
          endAnimalPhotos: [media('animals.jpg')],
          endAnimalVideos: media('animals.mp4'),
          clientSignature: Uint8List.fromList([4, 5]),
          endOdometerReading: 1200,
          offLoadChecklist: const [
            DeliveryChecklistItem(item: 'All lots offloaded', checked: true),
          ],
          buyerId: 'buyer-1',
        );
        final offlineService = OffloadingSyncService(
          () => repository,
          const SecureOffloadingQueueStore(),
          connectivity,
          statusStore: const SecureDeliveryStatusQueueStore(),
          replayStatus: (job) async {
            await repository.replayStatus(
              job.deliveryId,
              job.status,
              vehicleId: job.vehicleId,
            );
          },
        );
        for (final deliveryId in states.keys) {
          await offlineService.submitStatus(
            deliveryId: deliveryId,
            vehicleId: 'vehicle-1',
            status: DeliveryStatusUpdate.arrivedAtLocation,
          );
          await offlineService.submitStatus(
            deliveryId: deliveryId,
            vehicleId: 'vehicle-1',
            status: DeliveryStatusUpdate.offloadingStarted,
          );
          expect(
            await offlineService.submit(
              deliveryId: deliveryId,
              vehicleId: 'vehicle-1',
              submission: evidence,
            ),
            OffloadingSubmitResult.queued,
          );
        }
        expect(offlineService.pendingCount, 6);
        expect(states.values, everyElement(serverStatus));
        offlineService.dispose();
        // Relaunch: reconstruct the evidence from files, not from the form objects.
        final reconnectedService = OffloadingSyncService(
          () => repository,
          const SecureOffloadingQueueStore(),
          connectivity,
          statusStore: const SecureDeliveryStatusQueueStore(),
          replayStatus: (job) async {
            await repository.replayStatus(
              job.deliveryId,
              job.status,
              vehicleId: job.vehicleId,
            );
          },
        );
        connectivity.connected = true;
        await reconnectedService.flushPending();
        if (failureStage != 'none') {
          expect(reconnectedService.pendingCount, greaterThan(0));
          expect(await const SecureOffloadingQueueStore().load(), isNotEmpty);
          await reconnectedService.flushPending();
        }
        expect(states.values, everyElement('completed'));
        expect(await const SecureOffloadingQueueStore().load(), isEmpty);
        expect(reconnectedService.pendingCount, 0);
        expect(acceptedEvidence, hasLength(2));
        for (final body in acceptedEvidence.values) {
          expect(body['endAnimalPhotos'], ['uploads/photo_0.jpg']);
          expect(body['endAnimalVideos'], 'uploads/video.mp4');
          expect(body['clientSignature'], 'uploads/client-signature.png');
          expect(body['offLoadChecklist'], [
            {'item': 'All lots offloaded', 'checked': true},
          ]);
          expect(body['endMediaMetadata'], hasLength(2));
        }
        expect(
          requests.where((path) => path.endsWith('/complete-offloading')),
          hasLength(failureStage == 'completionAck' ? 3 : 2),
        );
        expect(
          requests.where((path) => path.endsWith('/status')),
          hasLength(4),
        );
        expect(await const SecureDeliveryStatusQueueStore().load(), isEmpty);
        expect(
          requests.indexWhere((path) => path.endsWith('/complete-offloading')),
          greaterThan(
            requests.lastIndexWhere((path) => path.endsWith('/status')),
          ),
        );
        reconnectedService.dispose();
        await connectivity.close();
      },
    );
  }

  test(
    'concurrent saves and acknowledgements preserve every remaining job',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'offloading-queue-test-',
      );
      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(pathChannel, (_) async => root.path);
      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() async {
        messenger.setMockMethodCallHandler(pathChannel, null);
        await root.delete(recursive: true);
      });
      const store = SecureOffloadingQueueStore();
      final bytes = Uint8List.fromList([1, 2, 3]);
      PhotoMeta media(String name) => PhotoMeta(
        photo: XFile.fromData(bytes, name: name),
        dateTime: DateTime.utc(2026, 10, 11),
        latitude: -24.29,
        longitude: 28.12,
      );
      final evidence = CompleteOffloadingSubmission(
        endAnimalPhotos: [media('animals.jpg')],
        endAnimalVideos: media('animals.mp4'),
        clientSignature: bytes,
        endOdometerReading: 1200,
        offLoadChecklist: const [],
        buyerId: 'buyer-1',
      );
      final jobs = await Future.wait([
        for (var i = 0; i < 6; i++)
          store.enqueue(
            deliveryId: 'delivery-$i',
            vehicleId: 'vehicle-1',
            submission: evidence,
          ),
      ]);
      expect(await store.load(), hasLength(6));
      await Future.wait([
        store.remove(jobs.first),
        store.enqueue(
          deliveryId: 'new-delivery',
          vehicleId: 'vehicle-1',
          submission: evidence,
        ),
      ]);
      // A fresh store simulates relaunching the app with the same saved manifest.
      final restored = await const SecureOffloadingQueueStore().load();
      expect(
        restored.map((job) => job.deliveryId),
        unorderedEquals([
          for (var i = 1; i < 6; i++) 'delivery-$i',
          'new-delivery',
        ]),
      );
      expect(restored.first.submission.clientSignature, bytes);
      expect(
        await restored.first.submission.endAnimalPhotos.first.photo
            .readAsBytes(),
        bytes,
      );
    },
  );
}

class _OfflineConnectivity implements ConnectivityMonitor {
  bool connected = false;
  final _events = StreamController<void>.broadcast();

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<void> get onConnected => _events.stream;

  Future<void> close() => _events.close();
}
