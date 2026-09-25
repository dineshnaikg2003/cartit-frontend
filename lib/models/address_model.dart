class AddressModel {
  final int id;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'India',
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? json['name'] ?? '',
      phone: json['phoneNumber'] ?? json['phone'] ?? '',
      street: json['addressLine1'] ?? json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['postalCode'] ?? json['zipCode'] ?? json['pincode'] ?? '',
      country: json['country'] ?? 'India',
      isDefault: json['defaultAddress'] ?? json['isDefault'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phone,
      'addressLine1': street,
      'city': city,
      'state': state,
      'country': country.isNotEmpty ? country : 'India',
      'postalCode': zipCode,
      'defaultAddress': isDefault,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
