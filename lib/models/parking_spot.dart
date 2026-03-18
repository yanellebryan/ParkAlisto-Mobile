enum SpotStatus { available, occupied, selected }

class ParkingSpot {
  final String id; // e.g. 'A1', 'B3'
  final String row;
  final int number;
  SpotStatus status;

  ParkingSpot({
    required this.id,
    required this.row,
    required this.number,
    this.status = SpotStatus.available,
  });

  ParkingSpot copyWith({SpotStatus? status}) {
    return ParkingSpot(
      id: id,
      row: row,
      number: number,
      status: status ?? this.status,
    );
  }
}
