import 'package:flutter/material.dart';

class GuardianLoginPage extends StatefulWidget {
  const GuardianLoginPage({super.key});

  @override
  State<GuardianLoginPage> createState() => _GuardianLoginPageState();
}

class _GuardianLoginPageState extends State<GuardianLoginPage> {
  final _formKey = GlobalKey<FormState>();
  String guardianId = '';
  String password = '';
  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: Replace this with real authentication logic!
    await Future.delayed(const Duration(seconds: 1));

    // On success, navigate to HomePage with guardian info
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {
        'userId': guardianId,
        'isPatient': false,
      },
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Login')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Guardian ID',
                      prefixIcon: Icon(Icons.family_restroom),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => guardianId = v,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please enter your Guardian ID'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onChanged: (v) => password = v,
                    validator: (v) => v == null || v.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}