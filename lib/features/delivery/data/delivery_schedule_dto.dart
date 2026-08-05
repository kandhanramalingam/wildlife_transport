class DeliveryScheduleDto {
  final String id;
  final String buyerId;
  final String buyerName;
  final String address;
  final String auctionId;
  final DateTime scheduleDate;
  final String deliveryStatus;
  final bool paymentStatus;

  const DeliveryScheduleDto({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.address,
    required this.auctionId,
    required this.scheduleDate,
    required this.deliveryStatus,
    required this.paymentStatus,
  });

  factory DeliveryScheduleDto.fromJson(Map<String, dynamic> json) {
    return DeliveryScheduleDto(
      id: json['_id'] as String,
      buyerId: json['buyerId'] as String,
      buyerName: (json['buyerName'] as String?)?.trim().isNotEmpty == true
          ? (json['buyerName'] as String).trim()
          : json['buyerId'].toString(),
      address: json['address'] as String,
      auctionId: json['auctionId'] as String,
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      deliveryStatus: json['deliveryStatus'] as String,
      paymentStatus: json['paymentStatus'] as bool,
    );
  }
}
