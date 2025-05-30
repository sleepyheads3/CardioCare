import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'patient_login_page.dart';
import '../widgets/animated_background.dart';

class PatientRegisterPage extends StatefulWidget {
  final String phoneNumber;

  const PatientRegisterPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PatientRegisterPage> createState() => _PatientRegisterPageState();
}

class _PatientRegisterPageState extends State<PatientRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dbService = DatabaseService();

  String name = '', gender = '', guardianMobile = '', password = '';
  int age = 0;
  String? patientId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBg(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Please provide your details to complete registration',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => name = v,
                            validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => age = int.tryParse(v) ?? 0,
                            validator: (v) => v!.isEmpty ? 'Please enter your age' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.people),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => gender = v,
                            validator: (v) => v!.isEmpty ? 'Please enter your gender' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Guardian Mobile Number',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => guardianMobile = v,
                            validator: (v) => v!.isEmpty ? 'Please enter guardian mobile' : null,
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
                            validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isLoading = true);
                                  try {
                                    // Generate unique Patient ID
                                    patientId = 'P${const Uuid().v4().substring(0, 6).toUpperCase()}';
                                    await _authService.registerWithEmail('${widget.phoneNumber}@hhm.com', password);
                                    await _dbService.createPatient({
                                      'id': patientId,
                                      'name': name,
                                      'age': age,
                                      'gender': gender,
                                      'mobile': widget.phoneNumber,
                                      'guardianMobile': guardianMobile,
                                    }, patientId!);

                                    if (!mounted) return;

                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Registration Successful'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Your registration is complete!'),
                                            const SizedBox(height: 10),
                                            Text('Patient ID: $patientId'),
                                            const SizedBox(height: 10),
                                            const Text('Please save this ID for future reference.'),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const PatientLoginPage()),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'Complete Registration',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          TextButton(
                            child: const Text('Already have an account? Login'),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const PatientLoginPage()),
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
          ),
        ],
      ),
    );
  }
}