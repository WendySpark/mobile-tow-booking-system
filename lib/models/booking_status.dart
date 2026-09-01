enum BookingStatus {
  pending,
  confirmed,
  enRoute,
  arrived,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get value => name;

  String get label => switch (this) {
    BookingStatus.pending => 'Pending',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.enRoute => 'Tow Truck En Route',
    BookingStatus.arrived => 'Tow Truck Arrived',
    BookingStatus.completed => 'Completed',
    BookingStatus.cancelled => 'Cancelled',
  };

  static BookingStatus fromValue(String value) => BookingStatus.values
      .firstWhere((s) => s.value == value, orElse: () => BookingStatus.pending);
}
