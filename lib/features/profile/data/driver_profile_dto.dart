import '../models/driver_profile.dart';

class DriverProfileDto {
  final Map<String, dynamic> _json;

  const DriverProfileDto._(this._json);

  factory DriverProfileDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Profile id and name are required');
    }
    return DriverProfileDto._(json);
  }

  DriverProfile toModel() {
    final vehicleJson = _json['vehicle'];
    final combinationJson = _json['vehiclecombination'];
    return DriverProfile(
      id: _json['id'] as String,
      name: _json['name'] as String,
      idNumber: _string('idNumber'),
      passportNumber: _string('passportNumber'),
      address: _string('address'),
      phone: _string('phone'),
      licenceNumber: _string('licenceNumber'),
      licenceCode: _string('licenceCode'),
      licenceExpiry: _date('licenceExpiry'),
      idPath: _string('idPath'),
      licencePath: _string('licencePath'),
      status: _string('status'),
      type: _string('type'),
      allocationStartDate: _date('allocationStartDate'),
      allocationEndDate: _date('allocationEndDate'),
      vehicle: vehicleJson is Map<String, dynamic>
          ? _vehicleFromJson(vehicleJson)
          : null,
      vehicleCombination: combinationJson is Map<String, dynamic>
          ? combinationJson
          : null,
    );
  }

  String? _string(String key) =>
      _json[key] is String ? _json[key] as String : null;

  DateTime? _date(String key) {
    final value = _string(key);
    return value == null ? null : DateTime.tryParse(value);
  }

  DriverVehicle _vehicleFromJson(Map<String, dynamic> json) {
    final id = json['_id'];
    if (id is! String) throw const FormatException('Vehicle id is required');
    return DriverVehicle(
      id: id,
      make: json['make'] is String ? json['make'] as String : null,
      year: json['year'] is num ? (json['year'] as num).toInt() : null,
      description: json['description'] is String
          ? json['description'] as String
          : null,
      registrationNumber: json['registrationNumber'] is String
          ? json['registrationNumber'] as String
          : null,
      licenceCode: json['licenceCode'] is String
          ? json['licenceCode'] as String
          : null,
      compartmentNumber: json['compartmentNumber'] is num
          ? (json['compartmentNumber'] as num).toInt()
          : null,
      active: json['active'] is bool ? json['active'] as bool : null,
      rate: json['rate'] is num ? json['rate'] as num : null,
      type: json['type'] is String ? json['type'] as String : null,
      code: json['code'] is String ? json['code'] as String : null,
    );
  }
}
