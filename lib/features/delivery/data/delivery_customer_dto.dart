class DeliveryCustomerDto {
  final String clientName;
  final String buyerId;
  final bool completed;
  final bool mainBuyer;
  final String deliveryId;

  const DeliveryCustomerDto({
    required this.clientName,
    required this.buyerId,
    required this.completed,
    required this.mainBuyer,
    required this.deliveryId,
  });

  factory DeliveryCustomerDto.fromJson(Map<String, dynamic> json) {
    final buyerId = json['value']?.toString() ?? '';
    final deliveryId = json['deliveryId']?.toString() ?? '';
    if (buyerId.isEmpty || deliveryId.isEmpty) {
      throw const FormatException('Customer response is missing an id');
    }

    final suppliedName = json['clientName']?.toString().trim();
    return DeliveryCustomerDto(
      clientName: suppliedName == null || suppliedName.isEmpty
          ? buyerId
          : suppliedName,
      buyerId: buyerId,
      completed: json['completed'] == true,
      mainBuyer: json['mainBuyer'] == true,
      deliveryId: deliveryId,
    );
  }
}
