// lib/fuels/edit_fuel_screen.dart
import 'package:flutter/material.dart';

import '../models/fuel_item.dart';
import '../services/fuel_service.dart';

class EditFuelScreen extends StatefulWidget {
  final FuelItem fuel;

  const EditFuelScreen({
    super.key,
    required this.fuel,
  });

  @override
  State<EditFuelScreen> createState() => _EditFuelScreenState();
}

class _EditFuelScreenState extends State<EditFuelScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _carbsController;
  late TextEditingController _caloriesController;
  late TextEditingController _sodiumController;
  late TextEditingController _notesController;

  bool _isFormValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final fuel = widget.fuel;

    _nameController = TextEditingController(text: fuel.name);
    _brandController = TextEditingController(text: fuel.brand);
    _carbsController =
        TextEditingController(text: fuel.carbsPerServing.toString());
    _caloriesController =
        TextEditingController(text: fuel.caloriesPerServing.toString());
    _sodiumController =
        TextEditingController(text: fuel.sodiumMg.toString());
    _notesController = TextEditingController(text: fuel.notes ?? '');

    _nameController.addListener(_updateFormValidity);
    _brandController.addListener(_updateFormValidity);
    _carbsController.addListener(_updateFormValidity);
    _caloriesController.addListener(_updateFormValidity);
    _sodiumController.addListener(_updateFormValidity);

    _updateFormValidity();
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateFormValidity);
    _brandController.removeListener(_updateFormValidity);
    _carbsController.removeListener(_updateFormValidity);
    _caloriesController.removeListener(_updateFormValidity);
    _sodiumController.removeListener(_updateFormValidity);

    _nameController.dispose();
    _brandController.dispose();
    _carbsController.dispose();
    _caloriesController.dispose();
    _sodiumController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final carbs = int.tryParse(_carbsController.text.trim());
    final calories = int.tryParse(_caloriesController.text.trim());
    final sodium = int.tryParse(_sodiumController.text.trim());

    final isValid = name.isNotEmpty &&
        brand.isNotEmpty &&
        carbs != null &&
        carbs > 0 &&
        calories != null &&
        calories > 0 &&
        sodium != null &&
        sodium >= 0;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _onSavePressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final carbs = int.parse(_carbsController.text.trim());
    final calories = int.parse(_caloriesController.text.trim());
    final sodium = int.parse(_sodiumController.text.trim());
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      await FuelService.instance.updateFuel(
        fuelId: widget.fuel.id,
        name: name,
        brand: brand,
        carbsPerServing: carbs,
        caloriesPerServing: calories,
        sodiumMg: sodium,
        notes: notes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fuel updated.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save fuel. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit fuel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Fuel name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return '> 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories (kcal)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return '> 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sodiumController,
                decoration: const InputDecoration(
                  labelText: 'Sodium (mg)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return '0 or more';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    _isFormValid && !_isSaving ? _onSavePressed : null,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update fuel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
