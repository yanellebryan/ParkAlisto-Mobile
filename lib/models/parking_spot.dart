enum SpotStatus { available, occupied, selected }

class ParkingSpot {
  final String id; // e.g. 'A1', 'B3'
  final String row;
  final int number;
  final String? locationId;
  final int? floor;
  SpotStatus status;
  
  String get label => '$row$number';

  ParkingSpot({
    required this.id,
    required this.row,
    required this.number,
    this.locationId,
    this.floor,
    this.status = SpotStatus.available,
  });

  /// Create a ParkingSpot from a Supabase JSON row
  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: (json['id'] as String?) ?? '',
      row: (json['row_letter'] as String?) ?? '',
      number: (json['spot_number'] as int?) ?? 0,
      locationId: json['location_id'] as String?,
      floor: json['floor'] as int?,
      status: (json['status'] as String?) == 'occupied'
          ? SpotStatus.occupied
          : SpotStatus.available,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'row_letter': row,
      'spot_number': number,
      'location_id': locationId,
      'floor': floor,
      'status': status == SpotStatus.occupied ? 'occupied' : 'available',
    };
  }

  ParkingSpot copyWith({SpotStatus? status, int? floor}) {
    return ParkingSpot(
      id: id,
      row: row,
      number: number,
      locationId: locationId,
      floor: floor ?? this.floor,
      status: status ?? this.status,
    );
  }
}
