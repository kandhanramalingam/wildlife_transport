class DriverProfile {
  final String id;
  final String name;
  final String? idNumber;
  final String? passportNumber;
  final String? address;
  final String? phone;
  final String? licenceNumber;
  final String? licenceCode;
  final DateTime? licenceExpiry;
  final String? idPath;
  final String? licencePath;
  final String? status;
  final String? type;
  final DateTime? allocationStartDate;
  final DateTime? allocationEndDate;
  final DriverVehicle? vehicle;
  final Map<String, dynamic>? vehicleCombination;

  const DriverProfile({
    required this.id,
    required this.name,
    this.idNumber,
    this.passportNumber,
    this.address,
    this.phone,
    this.licenceNumber,
    this.licenceCode,
    this.licenceExpiry,
    this.idPath,
    this.licencePath,
    this.status,
    this.type,
    this.allocationStartDate,
    this.allocationEndDate,
    this.vehicle,
    this.vehicleCombination,
  });
}

class DriverVehicle {
  final String id;
  final String? make;
  final int? year;
  final String? description;
  final String? registrationNumber;
  final String? licenceCode;
  final int? compartmentNumber;
  final bool? active;
  final num? rate;
  final String? type;
  final String? code;

  const DriverVehicle({
    required this.id,
    this.make,
    this.year,
    this.description,
    this.registrationNumber,
    this.licenceCode,
    this.compartmentNumber,
    this.active,
    this.rate,
    this.type,
    this.code,
  });
}
