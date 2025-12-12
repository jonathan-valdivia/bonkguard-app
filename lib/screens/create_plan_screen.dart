import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/plan_service.dart';
import '../state/user_profile_notifier.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedPattern = 'fixed'; // only option for now
  bool _isFormValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(_updateFormValidity);
    _durationController.addListener(_updateFormValidity);

    _updateFormValidity();
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateFormValidity);
    _durationController.removeListener(_updateFormValidity);

    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    final name = _nameController.text.trim();
    final durationText = _durationController.text.trim();
    final duration = int.tryParse(durationText);

    final isValid = name.isNotEmpty && duration != null && duration > 0;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _onSavePressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

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

    setState(() {
      _isSaving = true;
    });

    try {
      await PlanService.instance.createPlan(
        userId: profile.uid,
        name: name,
        durationMinutes: durationMinutes,
        patternType: _selectedPattern,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved.')),
      );

      // Go back to previous screen (Home, which links to My Plans, etc.)
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save plan. Please try again.'),
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
        title: const Text('Create Plan'),
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
              DropdownButtonFormField<String>(
                value: _selectedPattern,
                decoration: const InputDecoration(
                  labelText: 'Fuel pattern',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Fixed pattern'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedPattern = value;
                  });
                },
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
                    : const Text('Save plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
