// lib/data/default_fuels.dart
import '../models/fuel_item.dart';

class DefaultFuels {
  static final List<FuelItem> all = [
    FuelItem(
      id: 'carb_drink_mix',
      userId: null,
      name: 'High-Carb Drink Mix',
      brand: 'The Feed Lab',
      carbsPerServing: 30,      
      caloriesPerServing: 120,  
      sodiumMg: 150,            
      notes: 'Example default fuel',
      isDefault: true,
    ),
    FuelItem(
      id: 'maurten_160',
      userId: null,
      name: 'Maurten 160',
      brand: 'Maurten',
      carbsPerServing: 40,
      caloriesPerServing: 160,
      sodiumMg: 30,
      notes: null,
      isDefault: true,
    ),
    FuelItem(
      id: 'maurten_320',
      userId: null,
      name: 'Drink Mix 320',
      brand: 'Maurten',
      carbsPerServing: 80,      
      caloriesPerServing: 320,  
      sodiumMg: 245,            
      notes: null,
      isDefault: true,
    ),
    FuelItem(
      id: 'gel_generic',
      userId: null,
      name: 'Generic Gel',
      brand: 'Generic',
      carbsPerServing: 30,      
      caloriesPerServing: 120,  
      sodiumMg: 0,             
      notes: null,
      isDefault: true,
    ),
    FuelItem(
      id: 'bar_generic',
      userId: null,
      name: 'Generic Bar',
      brand: 'Generic',
      carbsPerServing: 30,
      caloriesPerServing: 150,
      sodiumMg: 0,
      notes: null,
      isDefault: true,
    ),
  ];
}
