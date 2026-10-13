import 'offloading_queue_store.dart';
import 'offloading_queue_store_stub.dart'
    if (dart.library.io) 'offloading_queue_store_io.dart'
    if (dart.library.js_interop) 'offloading_queue_store_web.dart'
    as implementation;

OffloadingQueueStore createOffloadingQueueStore() =>
    implementation.createOffloadingQueueStore();
