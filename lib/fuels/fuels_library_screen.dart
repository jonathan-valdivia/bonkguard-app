// lib/fuels/fuels_library_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fuel_item.dart';
import '../services/fuel_service.dart';
import '../state/user_profile_notifier.dart';
import 'add_fuel_screen.dart'; // 👈 NEW

class FuelsLibraryScreen extends StatelessWidget {
  const FuelsLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileNotifier>().profile;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuels Library'),
      ),
      body: StreamBuilder<List<FuelItem>>(
        stream: FuelService.instance.streamUserFuels(profile.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load fuels.\nPlease try again later.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          final fuels = snapshot.data ?? [];

          if (fuels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_drink_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No fuels found',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can add your favorite gels, drinks, and snacks here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: fuels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final fuel = fuels[index];

              final subtitle =
                  '${fuel.brand.isNotEmpty ? '${fuel.brand} • ' : ''}'
                  '${fuel.carbsPerServing} g carbs • '
                  '${fuel.caloriesPerServing} kcal • '
                  '${fuel.sodiumMg} mg sodium';

              return Card(
                elevation: 1,
                child: ListTile(
                  title: Text(fuel.name),
                  subtitle: Text(subtitle),
                  trailing: fuel.isDefault
                      ? const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : const Icon(Icons.edit, size: 18), // will hook later
                  onTap: fuel.isDefault ? null : () {},
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddFuelScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add fuel'),
      ),
    );
  }
}
