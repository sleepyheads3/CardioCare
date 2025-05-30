import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import 'patient_phone_verification_page.dart';
import 'guardian_register_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  final gunmetal = const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackgroundWidget(
            child: SizedBox.expand(), // Provide a non-null child!
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Heart Health Monitor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Please select your role',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        _buildRoleButton(
                          context,
                          'Patient',
                          Icons.person,
                          Colors.blue,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatientPhoneVerificationPage()),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildRoleButton(
                          context,
                          'Guardian',
                          Icons.family_restroom,
                          Colors.green,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GuardianRegisterPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(
      BuildContext context,
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}