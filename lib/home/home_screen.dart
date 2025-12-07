// lib/home/home_screen.dart
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/fuel_item.dart';
import '../models/fuel_event.dart';
import '../models/fuel_plan.dart';
import '../services/fueling_plan_service.dart';
import '../app_theme.dart';

import '../data/fuel_library.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic ride inputs
  final _hoursController = TextEditingController(text: '3');
  final _minutesController = TextEditingController(text: '0');
  late TextEditingController _carbsPerHourController;
  final _planNameController = TextEditingController();

  String _intensity = 'Z2'; // placeholder for now

  // Pattern fuel selections (we'll use IDs of FuelItem)
  String? _patternAId;
  String? _patternBId;
  String? _patternCId;

  FuelingPlan? _currentPlan;

  bool _isSavingPlan = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill carbs/hr from user profile
    _carbsPerHourController = TextEditingController(
      text: widget.profile.carbsPerHour.toString(),
    );

    // Default pattern: drink → gel → drink
    _patternAId = 'maurten_160';
    _patternBId = 'gel_generic';
    _patternCId = 'maurten_320';
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _carbsPerHourController.dispose();
    _planNameController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _fuelDropdownItems() {
    return FuelLibrary.list
        .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
        .toList();
  }

  Future<void> _generatePlan() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_patternAId == null || _patternBId == null || _patternCId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all pattern items (A, B, C).'),
        ),
      );
      return;
    }

    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final carbsPerHour =
        int.tryParse(_carbsPerHourController.text.trim()) ?? 60;

    final totalMinutes = hours * 60 + minutes;
    if (totalMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride duration must be greater than 0.')),
      );
      return;
    }

    final rideDuration = Duration(minutes: totalMinutes);

    final patternItems = [
      FuelLibrary.getById(_patternAId!)!,
      FuelLibrary.getById(_patternBId!)!,
      FuelLibrary.getById(_patternCId!)!,
    ];

    final rawName = _planNameController.text.trim();
    final planName = rawName.isEmpty
        ? 'Ride ${DateTime.now().toLocal()}'
        : rawName;

    final plan = FuelingPlanService.instance.generateFixedPatternPlan(
      userId: widget.profile.uid,
      rideDuration: rideDuration,
      targetCarbsPerHour: carbsPerHour,
      patternItems: patternItems,
      intervalMinutes: 20,
      startOffsetMinutes: 20,
      name: planName,
    );

    setState(() {
      _currentPlan = plan;
    });
  }

  Future<void> _saveCurrentPlan() async {
    final plan = _currentPlan;
    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No plan to save. Generate a plan first.'),
        ),
      );
      return;
    }

    if (_isSavingPlan) return;

    setState(() {
      _isSavingPlan = true;
    });

    try {
      await FuelingPlanService.instance.savePlan(plan);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved to your account.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save plan. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPlan = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Scaffold(
      appBar: AppBar(title: const BonkGuardLogo()),
      body: Container(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${profile.email}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Ride setup',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _planNameController,
                            decoration: const InputDecoration(
                              labelText: 'Plan name (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _hoursController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Hours',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final parsed = int.tryParse(value.trim());
                                    if (parsed == null || parsed < 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _minutesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Minutes',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final parsed = int.tryParse(value.trim());
                                    if (parsed == null ||
                                        parsed < 0 ||
                                        parsed >= 60) {
                                      return '0–59';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _intensity,
                            items: const [
                              DropdownMenuItem(
                                value: 'Z1',
                                child: Text('Zone 1 (easy)'),
                              ),
                              DropdownMenuItem(
                                value: 'Z2',
                                child: Text('Zone 2 (endurance)'),
                              ),
                              DropdownMenuItem(
                                value: 'Z3',
                                child: Text('Zone 3 (tempo)'),
                              ),
                              DropdownMenuItem(
                                value: 'Z4',
                                child: Text('Zone 4 (threshold)'),
                              ),
                              DropdownMenuItem(
                                value: 'Z5',
                                child: Text('Zone 5 (VO2 / hard)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _intensity = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Intensity',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _carbsPerHourController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Target carbs per hour (g)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Fuel pattern (A → B → C → repeat)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _patternAId,
                            items: _fuelDropdownItems(),
                            onChanged: (value) {
                              setState(() {
                                _patternAId = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Pattern A',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _patternBId,
                            items: _fuelDropdownItems(),
                            onChanged: (value) {
                              setState(() {
                                _patternBId = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Pattern B',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _patternCId,
                            items: _fuelDropdownItems(),
                            onChanged: (value) {
                              setState(() {
                                _patternCId = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Pattern C',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _generatePlan,
                              child: const Text('Generate plan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_currentPlan != null) _buildPlanSummary(_currentPlan!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSummary(FuelingPlan plan) {
    final totalCarbs = plan.totalCarbs(FuelLibrary.items);
    final totalCalories = plan.totalCalories(FuelLibrary.items);
    final hours = plan.rideDuration.inMinutes / 60.0;
    final carbsPerHour = totalCarbs / hours;

    // Build table rows with cumulative carbs
    int cumulativeCarbs = 0;
    final rows = <DataRow>[];

    for (final event in plan.events) {
      final item = FuelLibrary.getById(event.fuelItemId);
      final itemCarbs = (item?.carbsPerServing ?? 0) * event.servings;

      cumulativeCarbs += itemCarbs;

      final timeMinutes = event.minuteFromStart;
      final h = timeMinutes ~/ 60;
      final m = timeMinutes % 60;

      // Show as HH:MM even if H = 0, keeps it consistent
      final timeLabel =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

      rows.add(
        DataRow(
          cells: [
            DataCell(Text(timeLabel)),
            DataCell(Text(item?.name ?? event.fuelItemId)),
            DataCell(Text('$itemCarbs')),
            DataCell(Text('$cumulativeCarbs')),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Generated plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            if (plan.name != null)
              Text(plan.name!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Ride duration: ${plan.rideDuration.inMinutes} min'),
            Text('Target: ${plan.targetCarbsPerHour} g/h'),
            Text('Total carbs: $totalCarbs g'),
            if (totalCalories != null)
              Text('Total calories: $totalCalories kcal'),
            Text('Approx carbs/hour: ${carbsPerHour.toStringAsFixed(1)} g/h'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Fueling timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Table is horizontally scrollable in case it overflows
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 32,
                dataRowMinHeight: 30,
                dataRowMaxHeight: 36,
                columns: const [
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Fuel')),
                  DataColumn(label: Text('Carbs (g)')),
                  DataColumn(label: Text('Total (g)')),
                ],
                rows: rows,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isSavingPlan ? null : _saveCurrentPlan,
                icon: _isSavingPlan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSavingPlan ? 'Saving...' : 'Save plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
