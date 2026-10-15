enum DeliveryStatus {
  pending,
  loading,
  loadingCompleted,
  inProgress,
  atDeliveryPoint,
  offloading,
  completed;

  factory DeliveryStatus.fromApi(String value) {
    final normalized = value
        .trim()
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase()
        .replaceAll(RegExp(r'[-\s]+'), '_');
    return switch (normalized) {
      'loading_started' ||
      'loading_in_progress' ||
      'loading' => DeliveryStatus.loading,
      'loading_completed' || 'loaded' => DeliveryStatus.loadingCompleted,
      'started' ||
      'ongoing' ||
      'trip_started' ||
      'in_delivery' ||
      'in_progress' ||
      'inprogress' => DeliveryStatus.inProgress,
      'arrived' ||
      'arrived_at_location' ||
      'at_delivery_point' => DeliveryStatus.atDeliveryPoint,
      'offloading_started' ||
      'off_loading_started' ||
      'offloading' => DeliveryStatus.offloading,
      'offloading_completed' ||
      'off_loading_completed' ||
      'ended' ||
      'completed' => DeliveryStatus.completed,
      _ => DeliveryStatus.pending,
    };
  }
}

/// Values accepted by PATCH /driver-auth/delivery/{id}/status.
enum DeliveryStatusUpdate {
  pending('pending'),
  ready('ready'),
  started('started'),
  ongoing('ongoing'),
  ended('ended'),
  completed('completed'),
  hold('hold'),
  loadingInProgress('loading_in_progress'),
  loadingCompleted('loading_completed'),
  inDelivery('in_delivery'),
  arrivedAtLocation('arrived_at_location'),
  offloadingStarted('offloading_started');

  final String apiValue;

  const DeliveryStatusUpdate(this.apiValue);
}

class PickupStop {
  final int order;
  final String address;
  final List<String> lotNumbers;

  const PickupStop({
    this.order = 1,
    this.address = '',
    this.lotNumbers = const [],
  });
}

class DeliveryLotDetails {
  final String lotNumber;
  final String description;
  final int? quantity;
  final String status;
  final String comment;

  const DeliveryLotDetails({
    required this.lotNumber,
    this.description = '',
    this.quantity,
    this.status = '',
    this.comment = '',
  });
}

class DeliveryLoadingMedia {
  final String filePath;
  final String kind;
  final String? lotNumber;

  const DeliveryLoadingMedia({
    required this.filePath,
    required this.kind,
    this.lotNumber,
  });

  bool belongsToLot(String value) =>
      lotNumber?.trim().toLowerCase() == value.trim().toLowerCase();
}

class DeliveryAssignment {
  final String driverId;
  final String driverName;
  final String vehicleId;
  final String vehicleRegistrationNumber;
  final String vehicleDescription;
  final DeliveryStatus? status;
  final List<String> lotNumbers;
  final List<String> loadedLotNumbers;
  final List<String> deliveredLotNumbers;

  const DeliveryAssignment({
    required this.driverId,
    this.driverName = '',
    required this.vehicleId,
    this.vehicleRegistrationNumber = '',
    this.vehicleDescription = '',
    this.status,
    this.lotNumbers = const [],
    this.loadedLotNumbers = const [],
    this.deliveredLotNumbers = const [],
  });

  List<String> get allLotNumbers => {
    ...lotNumbers,
    ...loadedLotNumbers,
    ...deliveredLotNumbers,
  }.toList(growable: false);

  String get vehicleLabel {
    if (vehicleRegistrationNumber.isNotEmpty) {
      return vehicleRegistrationNumber;
    }
    if (vehicleDescription.isNotEmpty) return vehicleDescription;
    return vehicleId;
  }
}

class DeliveryLot {
  final String clientName;
  final String buyerId;
  final List<String> lotNumbers;
  final bool mainBuyer;
  final String deliveryId;
  final String address;
  final String farmName;
  final String companyName;
  final String contactNumber;
  final String latitude;
  final String longitude;
  final String? invoicePath;
  final int? loadingOrder;
  final bool? atDeliveryPointState;
  final DeliveryStatus status;
  final DeliveryAssignment? assignment;
  final DateTime? customerLocationCapturedAt;
  final bool offloadingSyncPending;

  const DeliveryLot({
    required this.clientName,
    required this.buyerId,
    this.lotNumbers = const [],
    required this.mainBuyer,
    required this.deliveryId,
    required this.address,
    this.farmName = '',
    this.companyName = '',
    this.contactNumber = '',
    this.latitude = '',
    this.longitude = '',
    this.invoicePath,
    this.loadingOrder,
    this.atDeliveryPointState,
    this.status = DeliveryStatus.pending,
    this.assignment,
    this.customerLocationCapturedAt,
    this.offloadingSyncPending = false,
  });

  bool get loadingCompleted => switch (status) {
    DeliveryStatus.loadingCompleted ||
    DeliveryStatus.inProgress ||
    DeliveryStatus.atDeliveryPoint ||
    DeliveryStatus.offloading ||
    DeliveryStatus.completed => true,
    _ => false,
  };
  bool get deliveryCompleted =>
      status == DeliveryStatus.completed || offloadingSyncPending;
  bool get atDeliveryPoint =>
      atDeliveryPointState ??
      (status == DeliveryStatus.atDeliveryPoint ||
          status == DeliveryStatus.offloading);
  String get invoicePathValue => invoicePath?.trim() ?? '';
  bool get hasInvoice => invoicePathValue.isNotEmpty;

  DeliveryLot copyWith({
    DeliveryStatus? status,
    List<String>? lotNumbers,
    bool? atDeliveryPoint,
    int? loadingOrder,
    DeliveryAssignment? assignment,
    String? latitude,
    String? longitude,
    DateTime? customerLocationCapturedAt,
    bool? offloadingSyncPending,
  }) {
    return DeliveryLot(
      clientName: clientName,
      buyerId: buyerId,
      lotNumbers: lotNumbers ?? this.lotNumbers,
      mainBuyer: mainBuyer,
      deliveryId: deliveryId,
      address: address,
      farmName: farmName,
      companyName: companyName,
      contactNumber: contactNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      invoicePath: invoicePath,
      loadingOrder: loadingOrder ?? this.loadingOrder,
      atDeliveryPointState: atDeliveryPoint ?? this.atDeliveryPoint,
      status: status ?? this.status,
      assignment: assignment ?? this.assignment,
      customerLocationCapturedAt:
          customerLocationCapturedAt ?? this.customerLocationCapturedAt,
      offloadingSyncPending:
          offloadingSyncPending ?? this.offloadingSyncPending,
    );
  }
}

class DeliveryModel {
  final String id;
  final String? buyerId;
  final String? auctionId;
  final DateTime dateTime;
  final String clientName;
  final String clientAddress;
  final DeliveryStatus status;
  final bool paymentStatus;
  final String? invoicePath;
  final List<DeliveryLot> lots;
  final DeliveryAssignment? assignment;
  final bool multiPickupPointJob;
  final bool multiplePickupPoint;
  final String? pickupNotice;
  final List<PickupStop> pickupStops;
  final int vehicleLotTotal;
  final int totalLots;
  final int assignedLots;
  final int deliveredLots;
  final int balanceLots;
  final List<String> balanceLotNumbers;
  final bool partialDelivery;
  final List<String> permits;
  final List<String> maps;
  final List<DeliveryLotDetails> lotDetails;
  final List<DeliveryAssignment> assignments;
  final List<String> startVehiclePhotos;
  final List<String> startAnimalPhotos;
  final String? onLoadAnimalsVideo;
  final List<String> onLoadAnimalsVideos;
  final List<DeliveryLoadingMedia> startMediaMetadata;
  final bool offloadingSyncPending;

  const DeliveryModel({
    required this.id,
    this.buyerId,
    this.auctionId,
    required this.dateTime,
    required this.clientName,
    required this.clientAddress,
    this.status = DeliveryStatus.pending,
    this.paymentStatus = false,
    this.invoicePath,
    this.lots = const [],
    this.assignment,
    this.multiPickupPointJob = false,
    this.multiplePickupPoint = false,
    this.pickupNotice,
    this.pickupStops = const [],
    this.vehicleLotTotal = 0,
    this.totalLots = 0,
    this.assignedLots = 0,
    this.deliveredLots = 0,
    this.balanceLots = 0,
    this.balanceLotNumbers = const [],
    this.partialDelivery = false,
    this.permits = const [],
    this.maps = const [],
    this.lotDetails = const [],
    this.assignments = const [],
    this.startVehiclePhotos = const [],
    this.startAnimalPhotos = const [],
    this.onLoadAnimalsVideo,
    this.onLoadAnimalsVideos = const [],
    this.startMediaMetadata = const [],
    this.offloadingSyncPending = false,
  });

  List<String> get allLoadingPhotos => [
    ...startVehiclePhotos,
    ...startAnimalPhotos,
  ];

  bool get hasLoadingMedia =>
      allLoadingPhotos.isNotEmpty ||
      startMediaMetadata.isNotEmpty ||
      onLoadAnimalsVideos.isNotEmpty ||
      (onLoadAnimalsVideo != null && onLoadAnimalsVideo!.isNotEmpty);

  bool get isMultiPickup =>
      multiPickupPointJob || multiplePickupPoint || pickupStops.isNotEmpty;

  List<PickupStop> get sortedPickupStops =>
      List.of(pickupStops)..sort((a, b) => a.order.compareTo(b.order));

  bool get isPartial =>
      partialDelivery ||
      (totalLots > 0 &&
          (assignedLots < totalLots || (deliveredLots > 0 && balanceLots > 0)));

  String get partialProgressLabel => '$deliveredLots / $totalLots';

  String get balanceLotsLabel => balanceLotNumbers.isNotEmpty
      ? 'Balance: ${balanceLotNumbers.join(', ')}'
      : '$balanceLots Remaining';

  bool get allLotsLoaded =>
      lots.isEmpty || lots.every((lot) => lot.loadingCompleted);

  bool get deliveryCompleted => lots.isNotEmpty
      ? lots.every((lot) => lot.deliveryCompleted)
      : status == DeliveryStatus.completed || offloadingSyncPending;

  bool get hasPendingOffloading =>
      offloadingSyncPending || lots.any((lot) => lot.offloadingSyncPending);

  /// Only a server-confirmed completion belongs in the Completed tab. Locally
  /// captured offloading remains available in Today until its upload succeeds.
  bool get completionSynced => !hasPendingOffloading && deliveryCompleted;

  bool get tripStarted =>
      (status == DeliveryStatus.inProgress ||
          status == DeliveryStatus.atDeliveryPoint ||
          status == DeliveryStatus.offloading ||
          (status == DeliveryStatus.completed && !deliveryCompleted)) &&
      allLotsLoaded;

  int get nextLoadingOrder {
    final highestStoredOrder = lots.fold<int>(0, (highest, lot) {
      final order = lot.loadingOrder ?? 0;
      return order > highest ? order : highest;
    });
    final loadedCount = lots.where((lot) => lot.loadingCompleted).length;
    return (highestStoredOrder > loadedCount
            ? highestStoredOrder
            : loadedCount) +
        1;
  }

  List<DeliveryLot> get lotsInOffloadingOrder {
    final indexedLots = lots.indexed.toList(growable: false);
    indexedLots.sort((a, b) {
      final aOrder = a.$2.loadingOrder ?? a.$1 + 1;
      final bOrder = b.$2.loadingOrder ?? b.$1 + 1;
      return bOrder.compareTo(aOrder);
    });
    return List.unmodifiable(indexedLots.map((entry) => entry.$2));
  }

  int get deliveryCount => lots.isEmpty ? 1 : lots.length;

  int get completedDeliveryCount => lots.isEmpty
      ? (status == DeliveryStatus.completed && !offloadingSyncPending ? 1 : 0)
      : lots
            .where(
              (lot) =>
                  lot.status == DeliveryStatus.completed &&
                  !lot.offloadingSyncPending,
            )
            .length;

  String get deliveryProgressLabel {
    final completed =
        '$completedDeliveryCount/$deliveryCount Delivery Completed';
    return hasPendingOffloading ? '$completed • Awaiting sync' : completed;
  }

  String get assignedVehicleId => assignment?.vehicleId ?? '';

  String get assignedVehicleLabel => assignment?.vehicleLabel ?? '';

  /// Retain all loading evidence when a customer upload or status response arrives.
  DeliveryModel withLoadingMediaFrom(DeliveryModel uploaded) {
    final videos = <String>{
      ...onLoadAnimalsVideos,
      if (onLoadAnimalsVideo?.isNotEmpty == true) onLoadAnimalsVideo!,
      ...uploaded.onLoadAnimalsVideos,
      if (uploaded.onLoadAnimalsVideo?.isNotEmpty == true)
        uploaded.onLoadAnimalsVideo!,
    }.toList();
    final metadata = {
      for (final media in startMediaMetadata) media.filePath: media,
      for (final media in uploaded.startMediaMetadata) media.filePath: media,
    };
    return copyWith(
      startVehiclePhotos: {
        ...startVehiclePhotos,
        ...uploaded.startVehiclePhotos,
      }.toList(),
      startAnimalPhotos: {
        ...startAnimalPhotos,
        ...uploaded.startAnimalPhotos,
      }.toList(),
      onLoadAnimalsVideos: videos,
      onLoadAnimalsVideo: videos.isEmpty ? null : videos.first,
      startMediaMetadata: metadata.values.toList(),
    );
  }

  List<String> lotNumbersForCustomer(DeliveryLot customer) {
    if (customer.lotNumbers.isNotEmpty) return customer.lotNumbers;
    if (lots.length > 1) return const [];
    return customer.assignment?.allLotNumbers ??
        assignment?.allLotNumbers ??
        const [];
  }

  DeliveryModel copyWith({
    DeliveryStatus? status,
    List<DeliveryLot>? lots,
    bool? partialDelivery,
    int? deliveredLots,
    int? balanceLots,
    int? totalLots,
    List<String>? balanceLotNumbers,
    List<PickupStop>? pickupStops,
    List<String>? permits,
    List<String>? maps,
    List<DeliveryLotDetails>? lotDetails,
    List<DeliveryAssignment>? assignments,
    DeliveryAssignment? assignment,
    List<String>? startVehiclePhotos,
    List<String>? startAnimalPhotos,
    String? onLoadAnimalsVideo,
    List<String>? onLoadAnimalsVideos,
    List<DeliveryLoadingMedia>? startMediaMetadata,
    bool? offloadingSyncPending,
  }) {
    return DeliveryModel(
      id: id,
      buyerId: buyerId,
      auctionId: auctionId,
      dateTime: dateTime,
      clientName: clientName,
      clientAddress: clientAddress,
      status: status ?? this.status,
      paymentStatus: paymentStatus,
      invoicePath: invoicePath,
      lots: lots ?? this.lots,
      assignment: assignment ?? this.assignment,
      multiPickupPointJob: multiPickupPointJob,
      multiplePickupPoint: multiplePickupPoint,
      pickupNotice: pickupNotice,
      pickupStops: pickupStops ?? this.pickupStops,
      vehicleLotTotal: vehicleLotTotal,
      totalLots: totalLots ?? this.totalLots,
      assignedLots: assignedLots,
      deliveredLots: deliveredLots ?? this.deliveredLots,
      balanceLots: balanceLots ?? this.balanceLots,
      balanceLotNumbers: balanceLotNumbers ?? this.balanceLotNumbers,
      partialDelivery: partialDelivery ?? this.partialDelivery,
      permits: permits ?? this.permits,
      maps: maps ?? this.maps,
      lotDetails: lotDetails ?? this.lotDetails,
      assignments: assignments ?? this.assignments,
      startVehiclePhotos: startVehiclePhotos ?? this.startVehiclePhotos,
      startAnimalPhotos: startAnimalPhotos ?? this.startAnimalPhotos,
      onLoadAnimalsVideo: onLoadAnimalsVideo ?? this.onLoadAnimalsVideo,
      onLoadAnimalsVideos: onLoadAnimalsVideos ?? this.onLoadAnimalsVideos,
      startMediaMetadata: startMediaMetadata ?? this.startMediaMetadata,
      offloadingSyncPending:
          offloadingSyncPending ?? this.offloadingSyncPending,
    );
  }
}
