import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final _db = FirebaseDatabase.instance.ref();

  // For real-time streaming vitals
  Stream<Map<String, dynamic>?> patientVitalsStream(String patientId) {
    return _db.child('vitals').child(patientId).onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // For updating vitals from ESP32/Bluetooth (used by patient only)
  Future<void> updatePatientVitals(String patientId, {double? bpm, double? spo2, double? temp}) async {
    await _db.child('vitals').child(patientId).update({
      'bpm': bpm,
      'spo2': spo2,
      'temp': temp,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  // Add this method to allow patient registration to work
  Future<void> createPatient(Map<String, dynamic> patientData, String patientId) async {
    await _db.child('patients').child(patientId).set(patientData);
  }
  DatabaseReference getPatientVitals(String patientId) {
    return _db.child('vitals').child(patientId);
  }
  Future<void> createGuardian(Map<String, dynamic> guardianData, String patientId) async {
    await _db.child('guardians').child(patientId).set(guardianData);
  }

// ...other existing methods...
}