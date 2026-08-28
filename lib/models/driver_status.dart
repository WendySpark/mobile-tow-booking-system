enum DriverStatus { available, busy, offline }

extension DriverStatusX on DriverStatus {
  String get value => name;

  String get label => switch (this) {
        DriverStatus.available => 'Available',
        DriverStatus.busy => 'Busy',
        DriverStatus.offline => 'Offline',
      };

  static DriverStatus fromValue(String value) => DriverStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => DriverStatus.available,
      );
}
