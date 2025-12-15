import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fuel_item.dart';
import '../services/fuel_service.dart';
import '../services/plan_service.dart';
import '../state/user_profile_notifier.dart';
import 'add_fuel_screen.dart';
import 'edit_fuel_screen.dart';

class FuelsLibraryScreen extends StatelessWidget {
  const FuelsLibraryScreen({super.key});

  Future<void> _confirmDeleteFuel({
    required BuildContext context,
    required String userId,
    required FuelItem fuel,
  }) async {
    if (fuel.isDefault) return;

    // ✅ Capture these BEFORE any awaits to avoid using context across async gaps
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Safety check: is fuel used by any plan?
    final isUsed = await PlanService.instance.userHasPlansUsingFuel(
      userId: userId,
      fuelId: fuel.id,
    );

    if (isUsed) {
      // Show info dialog using captured navigator context safely (dialog still needs a context)
      await showDialog<void>(
        context: navigator.context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Cannot delete fuel'),
            content: Text(
              '"${fuel.name}" is used in one or more of your plans.\n\n'
              'Edit those plans to remove it first, then delete the fuel.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: navigator.context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete fuel'),
          content: Text('Are you sure you want to delete "${fuel.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await FuelService.instance.deleteFuel(fuel.id);

      messenger.showSnackBar(
        const SnackBar(content: Text('Fuel deleted.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete fuel. Please try again.')),
      );
    }
  }

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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No fuels yet.\nTap + to add your first fuel.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Optional: defaults first, then alphabetical
          final sorted = [...fuels]..sort((a, b) {
            if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final fuel = sorted[index];

              final subtitleParts = <String>[];
              subtitleParts.add('${fuel.carbsPerServing}g carbs');
              subtitleParts.add('${fuel.caloriesPerServing} kcal');
              if (fuel.sodiumMg > 0) subtitleParts.add('${fuel.sodiumMg}mg sodium');
              if (fuel.brand.isNotEmpty) subtitleParts.add(fuel.brand);

              return Card(
                elevation: 1,
                child: ListTile(
                  title: Text(
                    fuel.isDefault ? '${fuel.name} (Default)' : fuel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    subtitleParts.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: fuel.isDefault ? 'Default fuel' : 'Edit',
                        icon: Icon(fuel.isDefault ? Icons.lock_outline : Icons.edit),
                        onPressed: fuel.isDefault
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditFuelScreen(fuel: fuel),
                                  ),
                                );
                              },
                      ),
                      IconButton(
                        tooltip: fuel.isDefault ? 'Default fuel' : 'Delete',
                        icon: Icon(
                          fuel.isDefault ? Icons.lock_outline : Icons.delete_outline,
                          color: fuel.isDefault ? null : Colors.red,
                        ),
                        onPressed: fuel.isDefault
                            ? null
                            : () => _confirmDeleteFuel(
                                  context: context,
                                  userId: profile.uid,
                                  fuel: fuel,
                                ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddFuelScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
