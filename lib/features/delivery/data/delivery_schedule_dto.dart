class DeliveryScheduleDto {
  final String id;
  final String buyerId;
  final String buyerName;
  final String address;
  final String companyName;
  final String contactNumber;
  final String auctionId;
  final DateTime scheduleDate;
  final String deliveryStatus;
  final bool paymentStatus;
  final String invoicePath;
  final List<DeliveryLotDto> lots;
  final DeliveryAssignmentDto? assignment;

  const DeliveryScheduleDto({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.address,
    this.companyName = '',
    this.contactNumber = '',
    required this.auctionId,
    required this.scheduleDate,
    required this.deliveryStatus,
    required this.paymentStatus,
    this.invoicePath = '',
    required this.lots,
    this.assignment,
  });

  factory DeliveryScheduleDto.fromJson(
    Map<String, dynamic> json, {
    String? authenticatedDriverId,
  }) {
    final id = json['_id'].toString();
    final mainBuyer = _record(
      json['buyer'] ?? json['client'] ?? json['buyerId'],
    );
    final rawBuyerId = json['buyerId'];
    final buyerId = mainBuyer.isEmpty
        ? _stringValue(rawBuyerId)
        : _firstString(mainBuyer, ['buyerId', 'value', 'id', '_id']);
    final buyerName = _name(
      json['buyerName'] ??
          _firstValue(mainBuyer, ['buyerName', 'clientName', 'name', 'label']),
      buyerId,
    );
    final address = _address(
      json['address'] ?? _firstValue(mainBuyer, ['address', 'farmAddress']),
      '',
    );
    final assignment = _parseCurrentAssignment(json, authenticatedDriverId);
    final deliveryStatus =
        assignment?.deliveryStatus ??
        json['driverDeliveryStatus']?.toString() ??
        json['deliveryStatus']?.toString() ??
        'pending';
    return DeliveryScheduleDto(
      id: id,
      buyerId: buyerId,
      buyerName: buyerName,
      address: address,
      companyName: _stringValue(
        json['companyName'] ?? _firstValue(mainBuyer, ['companyName']),
      ),
      contactNumber: _stringValue(
        json['contactNumber'] ??
            _firstValue(mainBuyer, ['contactNumber', 'phoneNumber', 'phone']),
      ),
      auctionId: json['auctionId'].toString(),
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      deliveryStatus: deliveryStatus,
      paymentStatus: json['paymentStatus'] == true,
      invoicePath: _stringValue(json['invoicePath']),
      assignment: assignment,
      lots: _parseLots(
        mainDeliveryId: id,
        mainBuyerId: buyerId,
        mainBuyerName: buyerName,
        mainAddress: address,
        mainFarmName: _stringValue(
          json['farmName'] ?? _firstValue(mainBuyer, ['farmName', 'farm_name']),
        ),
        mainCompanyName: _stringValue(
          json['companyName'] ?? _firstValue(mainBuyer, ['companyName']),
        ),
        mainContactNumber: _stringValue(
          json['contactNumber'] ??
              _firstValue(mainBuyer, ['contactNumber', 'phoneNumber', 'phone']),
        ),
        mainLatitude: _stringValue(
          _firstNonEmptyValue([
            json['clientLatitude'],
            mainBuyer['clientLatitude'],
            json['latitude'],
            json['lat'],
            mainBuyer['latitude'],
            mainBuyer['lat'],
          ]),
        ),
        mainLongitude: _stringValue(
          _firstNonEmptyValue([
            json['clientLongitude'],
            mainBuyer['clientLongitude'],
            json['longitude'],
            json['lng'],
            json['long'],
            mainBuyer['longitude'],
            mainBuyer['lng'],
            mainBuyer['long'],
          ]),
        ),
        mainInvoicePath: _stringValue(json['invoicePath']),
        mainLoadingOrder: _intValue(
          json['loadingOrder'] ?? json['loadingSequence'],
        ),
        mainStatus: deliveryStatus,
        mainAssignment: assignment,
        authenticatedDriverId: authenticatedDriverId,
        buyers: json['combinedLotBuyers'],
        deliveries: json['combinedLotDeliveries'],
      ),
    );
  }

  static List<DeliveryLotDto> _parseLots({
    required String mainDeliveryId,
    required String mainBuyerId,
    required String mainBuyerName,
    required String mainAddress,
    required String mainFarmName,
    required String mainCompanyName,
    required String mainContactNumber,
    required String mainLatitude,
    required String mainLongitude,
    required String mainInvoicePath,
    required int? mainLoadingOrder,
    required String mainStatus,
    required DeliveryAssignmentDto? mainAssignment,
    required String? authenticatedDriverId,
    required dynamic buyers,
    required dynamic deliveries,
  }) {
    final result = <DeliveryLotDto>[
      DeliveryLotDto(
        deliveryId: mainDeliveryId,
        buyerId: mainBuyerId,
        buyerName: mainBuyerName,
        address: mainAddress,
        farmName: mainFarmName,
        companyName: mainCompanyName,
        contactNumber: mainContactNumber,
        latitude: mainLatitude,
        longitude: mainLongitude,
        invoicePath: mainInvoicePath,
        loadingOrder: mainLoadingOrder,
        deliveryStatus: mainStatus,
        assignment: mainAssignment,
        mainBuyer: true,
      ),
    ];
    final buyerRows = buyers is List ? buyers : const [];
    final deliveryRows = deliveries is List ? deliveries : const [];

    for (var index = 0; index < buyerRows.length; index++) {
      final rawBuyer = buyerRows[index];
      final buyer = rawBuyer is Map
          ? Map<String, dynamic>.from(rawBuyer)
          : <String, dynamic>{'buyerId': rawBuyer};
      final client = _record(
        buyer['buyer'] ?? buyer['client'] ?? buyer['buyerId'] ?? buyer['value'],
      );
      final clientBuyerId = _firstString(client.isEmpty ? buyer : client, [
        'buyerId',
        'value',
        'id',
        '_id',
      ]);
      final buyerId = clientBuyerId.isNotEmpty
          ? clientBuyerId
          : _firstString(buyer, ['buyerId', 'value', 'id', '_id']);
      if (buyerId.isEmpty || buyerId == mainBuyerId) continue;

      Map<String, dynamic> delivery = const {};
      for (final rawDelivery in deliveryRows) {
        if (rawDelivery is! Map) continue;
        final candidate = Map<String, dynamic>.from(rawDelivery);
        final candidateBuyerId = _entityId(
          candidate['buyerId'] ??
              candidate['buyer'] ??
              candidate['client'] ??
              candidate['value'],
        );
        if (candidateBuyerId == buyerId) {
          delivery = candidate;
          break;
        }
      }
      if (delivery.isEmpty && index < deliveryRows.length) {
        final rawDelivery = deliveryRows[index];
        if (rawDelivery is Map) {
          delivery = Map<String, dynamic>.from(rawDelivery);
        } else if (rawDelivery != null) {
          delivery = <String, dynamic>{'deliveryId': rawDelivery};
        }
      }

      final assignment = _parseCurrentAssignment(<String, dynamic>{
        ...buyer,
        ...delivery,
      }, authenticatedDriverId);

      final deliveryId = _firstString(delivery, ['deliveryId', '_id', 'id']);
      result.add(
        DeliveryLotDto(
          deliveryId: deliveryId.isEmpty
              ? _firstString(buyer, ['deliveryId'])
              : deliveryId,
          buyerId: buyerId,
          buyerName: _name(
            _firstValue(client, ['buyerName', 'clientName', 'name', 'label']) ??
                buyer['buyerName'] ??
                buyer['clientName'] ??
                buyer['label'] ??
                buyer['name'] ??
                delivery['buyerName'],
            buyerId,
          ),
          address: _address(
            _firstValue(client, ['address', 'farmAddress']) ??
                buyer['address'] ??
                delivery['address'],
            '',
          ),
          farmName: _stringValue(
            _firstValue(client, ['farmName', 'farm_name']) ??
                buyer['farmName'] ??
                buyer['farm_name'] ??
                delivery['farmName'],
          ),
          companyName: _stringValue(
            _firstValue(client, ['companyName']) ??
                buyer['companyName'] ??
                delivery['companyName'],
          ),
          contactNumber: _stringValue(
            _firstValue(client, ['contactNumber', 'phoneNumber', 'phone']) ??
                buyer['contactNumber'] ??
                buyer['phoneNumber'] ??
                delivery['contactNumber'],
          ),
          latitude: _stringValue(
            _firstNonEmptyValue([
              client['clientLatitude'],
              client['latitude'],
              client['lat'],
              buyer['clientLatitude'],
              buyer['latitude'],
              buyer['lat'],
              delivery['clientLatitude'],
              delivery['latitude'],
              delivery['lat'],
            ]),
          ),
          longitude: _stringValue(
            _firstNonEmptyValue([
              client['clientLongitude'],
              client['longitude'],
              client['lng'],
              client['long'],
              buyer['clientLongitude'],
              buyer['longitude'],
              buyer['lng'],
              buyer['long'],
              delivery['clientLongitude'],
              delivery['longitude'],
              delivery['lng'],
              delivery['long'],
            ]),
          ),
          invoicePath: _stringValue(
            delivery['invoicePath'] ??
                buyer['invoicePath'] ??
                client['invoicePath'],
          ),
          loadingOrder: _intValue(
            delivery['loadingOrder'] ??
                delivery['loadingSequence'] ??
                buyer['loadingOrder'] ??
                buyer['loadingSequence'],
          ),
          deliveryStatus:
              (assignment?.deliveryStatus ??
                      delivery['driverDeliveryStatus'] ??
                      delivery['deliveryStatus'] ??
                      delivery['status'] ??
                      buyer['deliveryStatus'] ??
                      'pending')
                  .toString(),
          assignment: assignment,
          mainBuyer: false,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return null;
  }

  static Map<String, dynamic> _record(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};

  static String _entityId(dynamic value) {
    final record = _record(value);
    return record.isEmpty
        ? _stringValue(value)
        : _firstString(record, ['buyerId', 'value', 'id', '_id']);
  }

  static String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  static dynamic _firstNonEmptyValue(Iterable<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return null;
  }

  static int? _intValue(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString().trim() ?? '');

  static DeliveryAssignmentDto? _parseCurrentAssignment(
    Map<String, dynamic> json,
    String? authenticatedDriverId,
  ) {
    final direct = _record(
      json['currentAssignment'] ??
          json['driverAssignment'] ??
          json['assignment'],
    );
    if (direct.isNotEmpty) {
      return DeliveryAssignmentDto.fromJson(direct);
    }

    final rawAssignments = json['assignments'];
    final assignments = rawAssignments is List
        ? rawAssignments
              .whereType<Map>()
              .map((value) => Map<String, dynamic>.from(value))
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final driverId = authenticatedDriverId?.trim() ?? '';
    Map<String, dynamic>? selected;
    if (driverId.isNotEmpty) {
      for (final assignment in assignments) {
        final assignmentDriverId = _entityId(
          assignment['driverId'] ?? assignment['driver'],
        );
        if (assignmentDriverId == driverId) {
          selected = assignment;
          break;
        }
      }
    }
    if (selected == null) {
      for (final assignment in assignments) {
        if (assignment['isCurrentDriver'] == true ||
            assignment['isCurrentAssignment'] == true) {
          selected = assignment;
          break;
        }
      }
    }
    if (selected == null && assignments.length == 1) {
      selected = assignments.single;
    }
    if (selected != null) return DeliveryAssignmentDto.fromJson(selected);

    // Schedule endpoints are already scoped to the authenticated driver. A
    // singular top-level vehicle is therefore safe as a compatibility fallback;
    // never select from vehicleIds because that could expose another assignment.
    final vehicle = json['assignedVehicle'] ?? json['vehicle'];
    final vehicleId = _entityId(json['vehicleId'] ?? vehicle);
    if (vehicleId.isEmpty) return null;
    return DeliveryAssignmentDto.fromJson({
      'driverId': driverId,
      'driverName': json['driverName'],
      'vehicleId': json['vehicleId'] ?? vehicle,
      'deliveryStatus': json['driverDeliveryStatus'],
    });
  }

  static String _name(dynamic value, String fallback) {
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? fallback : name;
  }

  static String _address(dynamic value, String fallback) {
    final address = value?.toString().trim() ?? '';
    return address.isEmpty ? fallback : address;
  }
}

class DeliveryLotDto {
  final String deliveryId;
  final String buyerId;
  final String buyerName;
  final String address;
  final String farmName;
  final String companyName;
  final String contactNumber;
  final String latitude;
  final String longitude;
  final String invoicePath;
  final int? loadingOrder;
  final String deliveryStatus;
  final bool mainBuyer;
  final DeliveryAssignmentDto? assignment;

  const DeliveryLotDto({
    required this.deliveryId,
    required this.buyerId,
    required this.buyerName,
    required this.address,
    this.farmName = '',
    this.companyName = '',
    this.contactNumber = '',
    this.latitude = '',
    this.longitude = '',
    this.invoicePath = '',
    this.loadingOrder,
    required this.deliveryStatus,
    required this.mainBuyer,
    this.assignment,
  });
}

class DeliveryAssignmentDto {
  final String driverId;
  final String driverName;
  final String vehicleId;
  final String vehicleRegistrationNumber;
  final String vehicleDescription;
  final String? deliveryStatus;

  const DeliveryAssignmentDto({
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.vehicleRegistrationNumber,
    required this.vehicleDescription,
    required this.deliveryStatus,
  });

  factory DeliveryAssignmentDto.fromJson(Map<String, dynamic> json) {
    final driver = DeliveryScheduleDto._record(
      json['driverId'] ?? json['driver'],
    );
    final vehicle = DeliveryScheduleDto._record(
      json['vehicleId'] ?? json['vehicle'],
    );
    final rawVehicle = json['vehicleId'] ?? json['vehicle'];
    return DeliveryAssignmentDto(
      driverId: DeliveryScheduleDto._entityId(
        json['driverId'] ?? json['driver'],
      ),
      driverName: DeliveryScheduleDto._stringValue(
        json['driverName'] ??
            DeliveryScheduleDto._firstValue(driver, ['name', 'driverName']),
      ),
      vehicleId: DeliveryScheduleDto._entityId(rawVehicle),
      vehicleRegistrationNumber: DeliveryScheduleDto._stringValue(
        json['vehicleRegistrationNumber'] ??
            json['registrationNumber'] ??
            DeliveryScheduleDto._firstValue(vehicle, [
              'registrationNumber',
              'registration',
            ]),
      ),
      vehicleDescription: DeliveryScheduleDto._stringValue(
        json['vehicleDescription'] ??
            DeliveryScheduleDto._firstValue(vehicle, [
              'description',
              'make',
              'code',
            ]),
      ),
      deliveryStatus:
          DeliveryScheduleDto._stringValue(
            json['deliveryStatus'] ?? json['driverStatus'] ?? json['status'],
          ).isEmpty
          ? null
          : DeliveryScheduleDto._stringValue(
              json['deliveryStatus'] ?? json['driverStatus'] ?? json['status'],
            ),
    );
  }
}
