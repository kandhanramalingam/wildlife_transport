enum DeliveryStatus { pending, inProgress, completed }

class DeliveryModel {
  final String id;
  final DateTime dateTime;
  final String clientName;
  final String clientAddress;
  final DeliveryStatus status;

  const DeliveryModel({
    required this.id,
    required this.dateTime,
    required this.clientName,
    required this.clientAddress,
    this.status = DeliveryStatus.pending,
  });
}

// Dummy data for development
final List<DeliveryModel> todayDeliveries = [
  DeliveryModel(
    id: '1',
    dateTime: DateTime.now().copyWith(hour: 9, minute: 30),
    clientName: 'Rajesh Kumar',
    clientAddress: '42, Anna Nagar, Chennai - 600040',
  ),
  DeliveryModel(
    id: '2',
    dateTime: DateTime.now().copyWith(hour: 11, minute: 0),
    clientName: 'Priya Sharma',
    clientAddress: '7, T Nagar, Chennai - 600017',
  ),
];

final List<DeliveryModel> upcomingDeliveries = [
  DeliveryModel(
    id: '3',
    dateTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10, minute: 0),
    clientName: 'Suresh Nair',
    clientAddress: '3, Tambaram, Chennai - 600045',
  ),
  DeliveryModel(
    id: '4',
    dateTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 13, minute: 30),
    clientName: 'Lakshmi Iyer',
    clientAddress: '55, Mylapore, Chennai - 600004',
  ),
];
