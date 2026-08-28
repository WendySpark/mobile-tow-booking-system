class RepairCenter {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const RepairCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory RepairCenter.fromMap(String id, Map<String, dynamic> map) => RepairCenter(
        id: id,
        name: map['name'] as String? ?? '',
        address: map['address'] as String? ?? '',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}
