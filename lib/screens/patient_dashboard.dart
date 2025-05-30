import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/database_service.dart';
import '../widgets/animated_background.dart';

class PatientDashboard extends StatefulWidget {
  final String mobile;
  const PatientDashboard({super.key, required this.mobile});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final _dbService = DatabaseService();
  String? patientId;

  @override
  void initState() {
    super.initState();
    // In a real app, use mobile to lookup patientId in DB. Here, just use mobile.
    patientId = widget.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackgroundWidget(child: SizedBox.expand()),
          Center(
            child: StreamBuilder<DatabaseEvent>(
              stream: _dbService.getPatientVitals(patientId!).onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.snapshot.value != null) {
                  final event = snapshot.data!;
                  final data = Map<String, dynamic>.from(event.snapshot.value as Map);
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