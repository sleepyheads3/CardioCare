import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'patient_dashboard.dart';
import '../widgets/animated_background.dart';

class PatientLoginPage extends StatefulWidget {
  const PatientLoginPage({super.key});

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String mobile = '', password = '';

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
                        const Text('Patient Login', style: TextStyle(fontSize: 20)),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Mobile Number'),
                          keyboardType: TextInputType.phone,
                          onChanged: (v) => mobile = v,
                          validator: (v) => v!.isEmpty ? 'Enter mobile' : null,
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
                                await _authService.signInWithEmail('$mobile@hhm.com', password);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => PatientDashboard(mobile: mobile)),
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