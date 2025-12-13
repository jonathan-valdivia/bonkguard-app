// test/models/plan_test.dart
import 'package:bonkguard_app/models/plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Plan model', () {
    test('toJson and fromJson round-trip correctly with pattern fields', () {
      final original = Plan(
        id: 'plan123',
        userId: 'user1',
        name: 'My race plan',
        durationMinutes: 180,
        patternType: 'fixed',
        carbsPerHour: 80,
        intervalMinutes: 20,
        startOffsetMinutes: 20,
        patternFuelIds: const [
          'maurten_160',
          'gel_generic',
          'maurten_320',
        ],
        createdAt: DateTime.utc(2025, 1, 1, 12),
        updatedAt: DateTime.utc(2025, 1, 1, 13),
      );

      final json = original.toJson();
      final copy = Plan.fromJson(original.id, json);

      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.name, original.name);
      expect(copy.durationMinutes, original.durationMinutes);
      expect(copy.patternType, original.patternType);
      expect(copy.carbsPerHour, original.carbsPerHour);
      expect(copy.intervalMinutes, original.intervalMinutes);
      expect(copy.startOffsetMinutes, original.startOffsetMinutes);
      expect(copy.patternFuelIds, original.patternFuelIds);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
    });
  });
}
