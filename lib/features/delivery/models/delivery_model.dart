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
      'ended' ||
      'offloading' => DeliveryStatus.offloading,
      'offloading_completed' ||
      'off_loading_completed' ||
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

class DeliveryLot {
  final String clientName;
  final String buyerId;
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

  const DeliveryLot({
    required this.clientName,
    required this.buyerId,
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
  });

  bool get loadingCompleted => switch (status) {
    DeliveryStatus.loadingCompleted ||
    DeliveryStatus.inProgress ||
    DeliveryStatus.atDeliveryPoint ||
    DeliveryStatus.offloading ||
    DeliveryStatus.completed => true,
    _ => false,
  };
  bool get deliveryCompleted => status == DeliveryStatus.completed;
  bool get atDeliveryPoint =>
      atDeliveryPointState ??
      (status == DeliveryStatus.atDeliveryPoint ||
          status == DeliveryStatus.offloading);
  String get invoicePathValue => invoicePath?.trim() ?? '';
  bool get hasInvoice => invoicePathValue.isNotEmpty;

  DeliveryLot copyWith({
    DeliveryStatus? status,
    bool? atDeliveryPoint,
    int? loadingOrder,
  }) {
    return DeliveryLot(
      clientName: clientName,
      buyerId: buyerId,
      mainBuyer: mainBuyer,
      deliveryId: deliveryId,
      address: address,
      farmName: farmName,
      companyName: companyName,
      contactNumber: contactNumber,
      latitude: latitude,
      longitude: longitude,
      invoicePath: invoicePath,
      loadingOrder: loadingOrder ?? this.loadingOrder,
      atDeliveryPointState: atDeliveryPoint ?? this.atDeliveryPoint,
      status: status ?? this.status,
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
  });

  bool get allLotsLoaded =>
      lots.isEmpty || lots.every((lot) => lot.loadingCompleted);

  bool get deliveryCompleted =>
      status == DeliveryStatus.completed ||
      (lots.isNotEmpty && lots.every((lot) => lot.deliveryCompleted));

  bool get tripStarted =>
      (status == DeliveryStatus.inProgress ||
          status == DeliveryStatus.atDeliveryPoint ||
          status == DeliveryStatus.offloading) &&
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

  int get completedDeliveryCount => deliveryCompleted
      ? deliveryCount
      : lots.where((lot) => lot.deliveryCompleted).length;

  String get deliveryProgressLabel =>
      '$completedDeliveryCount/$deliveryCount Delivery Completed';

  DeliveryModel copyWith({DeliveryStatus? status, List<DeliveryLot>? lots}) {
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
    );
  }
}
