import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'guardian_dashboard.dart';
import '../widgets/animated_background.dart';

class GuardianLoginPage extends StatefulWidget {
  const GuardianLoginPage({super.key});

  @override
  State<GuardianLoginPage> createState() => _GuardianLoginPageState();
}

class _GuardianLoginPageState extends State<GuardianLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String patientId = '', password = '';

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
                        const Text('Guardian Login', style: TextStyle(fontSize: 20)),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Patient ID'),
                          onChanged: (v) => patientId = v,
                          validator: (v) => v!.isEmpty ? 'Enter patient ID' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          onChanged: (v) => password = v,
                          validator: (v) => v!.isEmpty ? 'Enter password' : null,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          child: const Text('Login'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                await _authService.signInWithEmail('$patientId@guardian.com', password);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => GuardianDashboard(patientId: patientId)),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Login failed: $e')),
                                );
                              }
                            }
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