import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // For now just log the values.
    // Next task: hook this up to Firestore.
    final name = _nameController.text.trim();
    final durationMinutes = int.parse(_durationController.text.trim());

    debugPrint('Saving plan: $name, $durationMinutes, $_selectedPattern');

    // TODO: Call Firestore save function
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
                onPressed: _onSavePressed,
                child: const Text('Save plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
