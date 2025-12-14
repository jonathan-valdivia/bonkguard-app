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
  late final TextEditingController _carbsPerHourController;
  late final TextEditingController _intervalMinutesController;
  late final TextEditingController _startOffsetMinutesController;

  // Fixed-only for MVP
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
    _durationController = TextEditingController(
      text: initial?.durationMinutes != null
          ? initial!.durationMinutes.toString()
          : '',
    );

    _carbsPerHourController = TextEditingController(
      text: (initial?.carbsPerHour ?? 60).toString(),
    );
    _intervalMinutesController = TextEditingController(
      text: (initial?.intervalMinutes ?? 20).toString(),
    );
    _startOffsetMinutesController = TextEditingController(
      text: (initial?.startOffsetMinutes ?? 20).toString(),
    );

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
    _carbsPerHourController.dispose();
    _intervalMinutesController.dispose();
    _startOffsetMinutesController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _fuelDropdownItems(List<FuelItem> fuels) {
    final sorted = [...fuels]..sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return sorted
        .map(
          (fuel) => DropdownMenuItem<String>(
            value: fuel.id,
            child: Text(
              fuel.isDefault ? '${fuel.name} (Default)' : fuel.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }

  void _ensureValidSelections(List<FuelItem> fuels) {
    if (fuels.isEmpty) return;

    bool exists(String? id) => id != null && fuels.any((f) => f.id == id);

    // Only set defaults if not already set or invalid
    if (!exists(_patternAId)) {
      _patternAId = fuels.first.id;
    }
    if (!exists(_patternBId)) {
      _patternBId = fuels.length > 1 ? fuels[1].id : fuels.first.id;
    }
    if (!exists(_patternCId)) {
      _patternCId = fuels.length > 2 ? fuels[2].id : fuels.first.id;
    }
  }

  Future<void> _onSavePressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_patternAId == null || _patternBId == null || _patternCId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select fuels for A, B, and C.')),
      );
      return;
    }

    final profile = context.read<UserProfileNotifier>().profile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No profile loaded. Please sign out and sign in again.'),
        ),
      );
      return;
    }

    if (_isSaving) return;

    final name = _nameController.text.trim();
    final durationMinutes = int.parse(_durationController.text.trim());
    final carbsPerHour = int.parse(_carbsPerHourController.text.trim());
    final intervalMinutes = int.parse(_intervalMinutesController.text.trim());
    final startOffsetMinutes =
        int.parse(_startOffsetMinutesController.text.trim());

    final patternFuelIds = [
      _patternAId!,
      _patternBId!,
      _patternCId!,
    ];

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await PlanService.instance.updatePlan(
          planId: widget.initialPlan!.id,
          name: name,
          durationMinutes: durationMinutes,
          patternType: _patternType,
          patternFuelIds: patternFuelIds,
          carbsPerHour: carbsPerHour,
          intervalMinutes: intervalMinutes,
          startOffsetMinutes: startOffsetMinutes,
        );
      } else {
        await PlanService.instance.createPlan(
          userId: profile.uid,
          name: name,
          durationMinutes: durationMinutes,
          patternType: _patternType,
          patternFuelIds: patternFuelIds,
          carbsPerHour: carbsPerHour,
          intervalMinutes: intervalMinutes,
          startOffsetMinutes: startOffsetMinutes,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Plan updated.' : 'Plan created.'),
        ),
      );

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save plan. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

                // Ensure dropdown selections always point to valid IDs
                _ensureValidSelections(fuels);

                final fuelItems = _fuelDropdownItems(fuels);

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
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _carbsPerHourController,
                                decoration: const InputDecoration(
                                  labelText: 'Target carbs/hour (g)',
                                  hintText: 'e.g. 80',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final parsed = int.tryParse(value.trim());
                                  if (parsed == null || parsed <= 0) {
                                    return 'Must be > 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _intervalMinutesController,
                                decoration: const InputDecoration(
                                  labelText: 'Interval (min)',
                                  hintText: 'e.g. 20',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final parsed = int.tryParse(value.trim());
                                  if (parsed == null || parsed <= 0) {
                                    return 'Must be > 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _startOffsetMinutesController,
                          decoration: const InputDecoration(
                            labelText: 'Start offset (min)',
                            hintText: 'e.g. 20',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed < 0) {
                              return 'Must be 0 or more';
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
