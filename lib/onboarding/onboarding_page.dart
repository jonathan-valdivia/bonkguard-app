// lib/onboarding/onboarding_page.dart
import 'package:bonkguard_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

class OnboardingPage extends StatefulWidget {
  final UserProfile profile;

  const OnboardingPage({super.key, required this.profile});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _weightController;
  late TextEditingController _carbsController;
  String _units = 'metric';
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    // Pre-fill from profile if available
    final weightKg = widget.profile.weightKg;
    _weightController = TextEditingController(
      text: weightKg != null ? weightKg.toStringAsFixed(1) : '',
    );

    _carbsController = TextEditingController(
      text: widget.profile.carbsPerHour.toString(),
    );

    _units = widget.profile.units;
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

      // Convert to kg if user picked imperial
      double weightKg = weight;
      if (_units == 'imperial') {
        // assume user entered weight in pounds
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
        data: {
          'weightKg': weightKg,
          'carbsPerHour': carbs,
          'units': _units,
          'onboardingComplete': true,
        },
      );

      if (!mounted) return;

      // Go to main home screen after saving
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _HomePlaceholder()),
      );
    } catch (e) {
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
      appBar: AppBar(title: const Text('Set up BonkGuard')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tell us a bit about you',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
                        value: _units,
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
                              : const Text('Save and continue'),
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

// For now, reuse the same placeholder home as in AuthGate.
// Later we'll centralize this in a single place.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const BonkGuardLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to BonkGuard, ${user?.email ?? 'athlete'}!'),
      ),
    );
  }
}
