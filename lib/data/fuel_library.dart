// lib/data/fuel_library.dart

import '../models/fuel_item.dart';

class FuelLibrary {
  FuelLibrary._(); // private constructor – static only

  /// Core MVP fuel items
  static const Map<String, FuelItem> items = {
    'maurten_160': FuelItem(
      id: 'maurten_160',
      name: 'Maurten 160',
      type: FuelItemType.drinkMix,
      carbsPerServing: 40,
      caloriesPerServing: 160,
      description: 'One bottle (500–750ml)',
    ),
    'maurten_320': FuelItem(
      id: 'maurten_320',
      name: 'Maurten 320',
      type: FuelItemType.drinkMix,
      carbsPerServing: 80,
      caloriesPerServing: 320,
      description: 'One bottle (500–750ml)',
    ),
    'gel_generic': FuelItem(
      id: 'gel_generic',
      name: 'Generic Gel',
      type: FuelItemType.gel,
      carbsPerServing: 25,
      caloriesPerServing: 100,
      description: 'Single gel packet',
    ),
    'bar_generic': FuelItem(
      id: 'bar_generic',
      name: 'Generic Bar',
      type: FuelItemType.solid,
      carbsPerServing: 30,
      caloriesPerServing: 150,
      description: 'One bar',
    ),
  };

  /// All items as a list (useful for dropdowns)
  static List<FuelItem> get list => items.values.toList();

  /// Lookup helper
  static FuelItem? getById(String id) => items[id];
}
