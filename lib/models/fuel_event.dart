// lib/models/fuel_event.dart

class FuelEvent {
  /// Minutes from the start of the ride
  final int minuteFromStart;

  /// ID of the FuelItem used (we'll look it up from the library)
  final String fuelItemId;

  /// How many servings of this item at this time (usually 1)
  final int servings;

  /// Optional notes, like "take with water" etc.
  final String? note;

  FuelEvent({
    required this.minuteFromStart,
    required this.fuelItemId,
    this.servings = 1,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'minuteFromStart': minuteFromStart,
      'fuelItemId': fuelItemId,
      'servings': servings,
      'note': note,
    };
  }

  factory FuelEvent.fromMap(Map<String, dynamic> map) {
    return FuelEvent(
      minuteFromStart: map['minuteFromStart'] as int,
      fuelItemId: map['fuelItemId'] as String,
      servings: map['servings'] as int? ?? 1,
      note: map['note'] as String?,
    );
  }
}
