import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plan.dart';
import '../models/fuel_item.dart';
import '../services/fuel_service.dart';
import '../services/plan_service.dart';
import '../state/user_profile_notifier.dart';

class CreatePlanScreen extends StatefulWidget {
  final Plan? initialPlan;

  const CreatePlanScreen({super.key, this.initialPlan});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _durationController;

  // Pattern type fixed-only for MVP
  final String _patternType = 'fixed';

  // Selected fuel IDs (A/B/C)
  String? _patternAId;
  String? _patternBId;
  String? _patternCId;

  bool _isSaving = false;

  bool get _isEditing => widget.initialPlan != null;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialPlan;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _durationController =
        TextEditingController(text: (initial?.durationMinutes ?? '').toString());

    // If editing and we already have saved patternFuelIds, prefill them
    final ids = initial?.patternFuelIds;
    if (ids != null && ids.length >= 3) {
      _patternAId = ids[0];
      _patternBId = ids[1];
      _patternCId = ids[2];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // For BG-192 we’re loading fuels + selecting them;
    // Saving the fuel IDs into the plan doc is BG-193/194,
    // but it’s safe to require selection now to prevent half-baked plans.
    if (_patternAId == null || _patternBId == null || _patternCId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select fuels for A, B, and C.')),
      );
      return;
    }

    if (_isSaving) return;

    final profile = context.read<UserProfileNotifier>().profile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No profile loaded. Please sign out and sign in again.'),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final durationMinutes = int.parse(_durationController.text.trim());

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await PlanService.instance.updatePlan(
          planId: widget.initialPlan!.id,
          name: name,
          durationMinutes: durationMinutes,
          patternType: _patternType,
        );
      } else {
        await PlanService.instance.createPlan(
          userId: profile.uid,
          name: name,
          durationMinutes: durationMinutes,
          patternType: _patternType,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Plan updated.' : 'Plan created.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save plan. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<DropdownMenuItem<String>> _fuelDropdownItems(List<FuelItem> fuels) {
    // Optional: sort defaults first, then alphabetical name
    final sorted = [...fuels]..sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return sorted
        .map(
          (fuel) => DropdownMenuItem(
            value: fuel.id,
            child: Text(
              fuel.isDefault ? '${fuel.name} (Default)' : fuel.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileNotifier>().profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plan' : 'Create Plan'),
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<FuelItem>>(
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
                            'No fuels available',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add fuels in the Fuels Library first, then come back.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final fuelItems = _fuelDropdownItems(fuels);

                // If selections are null (new screen) choose sensible defaults
                _patternAId ??= fuels.first.id;
                _patternBId ??= fuels.length > 1 ? fuels[1].id : fuels.first.id;
                _patternCId ??= fuels.length > 2 ? fuels[2].id : fuels.first.id;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Plan name',
                            hintText: 'e.g. LOTOJA race plan',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a plan name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration (minutes)',
                            hintText: 'e.g. 360',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a duration';
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Duration must be a positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Fuel pattern (A → B → C → repeat)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          value: _patternAId,
                          items: fuelItems,
                          decoration: const InputDecoration(
                            labelText: 'Pattern A',
                          ),
                          onChanged: (value) {
                            setState(() => _patternAId = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _patternBId,
                          items: fuelItems,
                          decoration: const InputDecoration(
                            labelText: 'Pattern B',
                          ),
                          onChanged: (value) {
                            setState(() => _patternBId = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _patternCId,
                          items: fuelItems,
                          decoration: const InputDecoration(
                            labelText: 'Pattern C',
                          ),
                          onChanged: (value) {
                            setState(() => _patternCId = value);
                          },
                        ),

                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isSaving ? null : _onSavePressed,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isEditing ? 'Update plan' : 'Save plan'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
