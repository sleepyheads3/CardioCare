import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/animated_background.dart';

class GuardianDashboard extends StatelessWidget {
  final String patientId;
  const GuardianDashboard({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final _dbService = DatabaseService();
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBg(),
          Center(
            child: StreamBuilder(
              stream: _dbService.getPatientVitals(patientId).onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                  return Card(
                    margin: const EdgeInsets.all(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Patient ID: $patientId', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text('Heart Rate: ${data['heartRate']} bpm'),
                          Text('SpO₂: ${data['spo2']} %'),
                          Text('Temperature: ${data['temperature']} °C'),
                          const SizedBox(height: 16),
                          Text('Prediction: ${data['prediction'] ?? "Normal"}'),
                        ],
                      ),
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }
}