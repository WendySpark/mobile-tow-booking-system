class RepairCenter {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// Uid of the Workshop account that owns/manages this center, or null
  /// for a center Admin seeded directly (see ManageRepairCentersScreen).
  /// By convention a Workshop-owned center's Firestore doc id equals this
  /// uid, so "get my center" is a direct doc lookup, not a query.
  final String? ownerUid;

  const RepairCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.ownerUid,
  });

  factory RepairCenter.fromMap(String id, Map<String, dynamic> map) =>
      RepairCenter(
        id: id,
        name: map['name'] as String? ?? '',
        address: map['address'] as String? ?? '',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        ownerUid: map['ownerUid'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'ownerUid': ownerUid,
  };

  // See Vehicle.== — same StreamBuilder re-identity issue applies here
  // since this is also used as a DropdownButtonFormField value.
  @override
  bool operator ==(Object other) => other is RepairCenter && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
