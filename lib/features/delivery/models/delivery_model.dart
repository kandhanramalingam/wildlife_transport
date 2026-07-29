enum DeliveryStatus {
  pending,
  inProgress,
  completed;

  factory DeliveryStatus.fromApi(String value) {
    return switch (value.toLowerCase()) {
      'in_progress' || 'inprogress' => DeliveryStatus.inProgress,
      'completed' => DeliveryStatus.completed,
      _ => DeliveryStatus.pending,
    };
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
