// lib/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

import 'package:provider/provider.dart';
import '../state/user_profile_notifier.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _weightController;
  late TextEditingController _carbsController;
  String _units = 'metric';
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _carbsController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<UserProfileNotifier>().profile;

    if (profile != null && _carbsController.text.isEmpty) {
      _units = profile.units;

      double? displayWeight;
      if (profile.weightKg != null) {
        if (_units == 'imperial') {
          displayWeight = profile.weightKg! / 0.45359237;
        } else {
          displayWeight = profile.weightKg;
        }
      }

      _weightController.text = displayWeight != null
          ? displayWeight.toStringAsFixed(1)
          : '';
      _carbsController.text = profile.carbsPerHour.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final weightText = _weightController.text.trim();
      final carbsText = _carbsController.text.trim();

      final weight = double.tryParse(weightText);
      final carbs = int.tryParse(carbsText);

      if (weight == null || carbs == null) {
        setState(() {
          _errorText = 'Please enter valid values.';
        });
        return;
      }

      // Convert to kg for storage
      double weightKg = weight;
      if (_units == 'imperial') {
        weightKg = weight * 0.45359237;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorText = 'No logged-in user found.';
        });
        return;
      }

      await UserProfileService.instance.updateProfile(
        uid: user.uid,
        data: {'weightKg': weightKg, 'carbsPerHour': carbs, 'units': _units},
      );

      // Reload updated profile from Firestore
      final updatedProfile = await UserProfileService.instance.getUserProfile(
        user.uid,
      );

      if (!mounted) return;

      if (updatedProfile == null) {
        setState(() {
          _errorText = 'Unable to load your updated profile.';
        });
        return;
      }

      context.read<UserProfileNotifier>().updateProfile(updatedProfile);

      // Return the updated profile to the caller (HomeScreen)
      Navigator.of(context).pop<UserProfile>(updatedProfile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Something went wrong. Please try again.';
      });
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
    final isImperial = _units == 'imperial';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorText != null) ...[
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Weight
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: isImperial ? 'Weight (lb)' : 'Weight (kg)',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your weight';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter a valid weight';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Units dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _units,
                        decoration: const InputDecoration(
                          labelText: 'Units',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'metric',
                            child: Text('Metric (kg)'),
                          ),
                          DropdownMenuItem(
                            value: 'imperial',
                            child: Text('Imperial (lb)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _units = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Carbs per hour
                      TextFormField(
                        controller: _carbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target carbs per hour (g)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your target carbs per hour';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
