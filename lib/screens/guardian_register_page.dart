import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'guardian_login_page.dart';
import '../widgets/animated_background.dart';


class GuardianRegisterPage extends StatefulWidget {
  const GuardianRegisterPage({super.key});

  @override
  State<GuardianRegisterPage> createState() => _GuardianRegisterPageState();
}

class _GuardianRegisterPageState extends State<GuardianRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dbService = DatabaseService();

  String name = '', patientId = '', mobile = '', password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBg(),
          Center(
            child: SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text('Guardian Registration', style: TextStyle(fontSize: 20)),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Guardian Name'),
                          onChanged: (v) => name = v,
                          validator: (v) => v!.isEmpty ? 'Enter name' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Patient ID'),
                          onChanged: (v) => patientId = v,
                          validator: (v) => v!.isEmpty ? 'Enter patient ID' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Guardian Mobile Number'),
                          keyboardType: TextInputType.phone,
                          onChanged: (v) => mobile = v,
                          validator: (v) => v!.isEmpty ? 'Enter mobile' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          onChanged: (v) => password = v,
                          validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          child: const Text('Register'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                await _authService.registerWithEmail('$patientId@guardian.com', password);
                                await _dbService.createGuardian({
                                  'name': name,
                                  'patientId': patientId,
                                  'mobile': mobile,
                                }, patientId);
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Registration Successful'),
                                    content: Text('Guardian registered for Patient ID: $patientId'),
                                    actions: [
                                      TextButton(
                                        child: const Text('OK'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const GuardianLoginPage()),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                        TextButton(
                          child: const Text('Already have an account? Login'),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const GuardianLoginPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}