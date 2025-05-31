import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact.dart';

class DatabaseService {
  final _db = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<List<EmergencyContact>> getEmergencyContacts(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('emergency_contacts')
          .get();

      return snapshot.docs
          .map((doc) => EmergencyContact.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get emergency contacts: $e');
    }
  }

  Future<void> addEmergencyContact(String patientId, EmergencyContact contact) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('emergency_contacts')
          .doc(contact.id)
          .set(contact.toMap());
    } catch (e) {
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  Future<void> deleteEmergencyContact(String patientId, String contactId) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete emergency contact: $e');
    }
  }

  Future<void> setPrimaryContact(String patientId, String contactId) async {
    try {
      // First, set all contacts to non-primary
      final batch = _firestore.batch();
      final contacts = await getEmergencyContacts(patientId);
      
      for (final contact in contacts) {
        batch.update(
          _firestore
              .collection('patients')
              .doc(patientId)
              .collection('emergency_contacts')
              .doc(contact.id),
          {'isPrimary': false},
        );
      }

      // Then set the selected contact as primary
      batch.update(
        _firestore
            .collection('patients')
            .doc(patientId)
            .collection('emergency_contacts')
            .doc(contactId),
        {'isPrimary': true},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set primary contact: $e');
    }
  }
}