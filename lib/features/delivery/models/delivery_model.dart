enum DeliveryStatus {
  pending,
  inProgress,
  completed;

  factory DeliveryStatus.fromApi(String value) {
    return switch (value.toLowerCase()) {
      'started' || 'in_progress' || 'inprogress' => DeliveryStatus.inProgress,
      'completed' => DeliveryStatus.completed,
      _ => DeliveryStatus.pending,
    };
  }
}

class DeliveryCustomer {
  final String clientName;
  final String buyerId;
  final bool completed;
  final bool mainBuyer;
  final String deliveryId;

  const DeliveryCustomer({
    required this.clientName,
    required this.buyerId,
    required this.completed,
    required this.mainBuyer,
    required this.deliveryId,
  });

  DeliveryCustomer copyWith({bool? completed}) {
    return DeliveryCustomer(
      clientName: clientName,
      buyerId: buyerId,
      completed: completed ?? this.completed,
      mainBuyer: mainBuyer,
      deliveryId: deliveryId,
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

  const DeliveryModel({
    required this.id,
    this.buyerId,
    this.auctionId,
    required this.dateTime,
    required this.clientName,
    required this.clientAddress,
    this.status = DeliveryStatus.pending,
    this.paymentStatus = false,
  });

  DeliveryModel copyWith({DeliveryStatus? status}) {
    return DeliveryModel(
      id: id,
      buyerId: buyerId,
      auctionId: auctionId,
      dateTime: dateTime,
      clientName: clientName,
      clientAddress: clientAddress,
      status: status ?? this.status,
      paymentStatus: paymentStatus,
    );
  }
}
