import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Patient related operations
  Future<void> createPatient(Map<String, dynamic> data, String patientId) async {
    try {
      // Add timestamp to the data
      data['createdAt'] = ServerValue.timestamp;
      data['lastUpdated'] = ServerValue.timestamp;
      
      // Create patient record
      await _db.child('patients').child(patientId).set(data);
      
      // Create a vitals node for the patient
      await _db.child('vitals').child(patientId).set({
        'lastUpdated': ServerValue.timestamp,
        'heartRate': null,
        'bloodPressure': null,
        'temperature': null,
        'oxygenLevel': null,
      });
    } catch (e) {
      debugPrint('Error creating patient: $e');
      rethrow;
    }
  }

  // Guardian related operations
  Future<void> createGuardian(Map<String, dynamic> data, String guardianId) async {
    try {
      // Add timestamp to the data
      data['createdAt'] = ServerValue.timestamp;
      data['lastUpdated'] = ServerValue.timestamp;
      
      // Create guardian record
      await _db.child('guardians').child(guardianId).set(data);
      
      // Create a patients list for the guardian
      await _db.child('guardian_patients').child(guardianId).set({
        'lastUpdated': ServerValue.timestamp,
        'patients': [],
      });
    } catch (e) {
      debugPrint('Error creating guardian: $e');
      rethrow;
    }
  }

  // Get patient data
  Future<Map<String, dynamic>?> getPatientData(String patientId) async {
    try {
      final snapshot = await _db.child('patients').child(patientId).get();
      if (!snapshot.exists) {
        debugPrint('No patient data found for ID: $patientId');
        return null;
      }
      return snapshot.value as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting patient data: $e');
      rethrow;
    }
  }

  // Get guardian data
  Future<Map<String, dynamic>?> getGuardianData(String guardianId) async {
    try {
      final snapshot = await _db.child('guardians').child(guardianId).get();
      if (!snapshot.exists) {
        debugPrint('No guardian data found for ID: $guardianId');
        return null;
      }
      return snapshot.value as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting guardian data: $e');
      rethrow;
    }
  }

  // Link patient to guardian
  Future<void> linkPatientToGuardian(String guardianId, String patientId) async {
    try {
      // Verify both patient and guardian exist
      final patientSnapshot = await _db.child('patients').child(patientId).get();
      final guardianSnapshot = await _db.child('guardians').child(guardianId).get();

      if (!patientSnapshot.exists) {
        throw Exception('Patient not found');
      }
      if (!guardianSnapshot.exists) {
        throw Exception('Guardian not found');
      }

      // Add patient to guardian's list
      await _db.child('guardian_patients').child(guardianId).child('patients').push().set({
        'patientId': patientId,
        'linkedAt': ServerValue.timestamp,
      });

      // Add guardian to patient's guardians list
      await _db.child('patient_guardians').child(patientId).child('guardians').push().set({
        'guardianId': guardianId,
        'linkedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error linking patient to guardian: $e');
      rethrow;
    }
  }

  // Get patient vitals
  DatabaseReference getPatientVitals(String patientId) {
    try {
      return _db.child('vitals').child(patientId);
    } catch (e) {
      debugPrint('Error getting patient vitals reference: $e');
      rethrow;
    }
  }

  // Update patient vitals
  Future<void> updatePatientVitals(String patientId, Map<String, dynamic> vitals) async {
    try {
      // Verify patient exists
      final patientSnapshot = await _db.child('patients').child(patientId).get();
      if (!patientSnapshot.exists) {
        throw Exception('Patient not found');
      }

      vitals['lastUpdated'] = ServerValue.timestamp;
      await _db.child('vitals').child(patientId).update(vitals);
    } catch (e) {
      debugPrint('Error updating patient vitals: $e');
      rethrow;
    }
  }
}