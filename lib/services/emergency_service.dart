import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/emergency_contact.dart';
import '../models/risk_type.dart';

class EmergencyService {
  static const String _ambulanceNumber = '911';
  static const String _googlePlacesApiKey = 'YOUR_API_KEY'; // Replace with your API key

  Future<void> sendEmergencySMS(EmergencyContact contact, RiskType riskType, String patientId) async {
    if (!contact.receiveSMS) return;

    final message = riskType.messageTemplate;
    final uri = Uri.parse('sms:${contact.phoneNumber}?body=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch SMS');
    }
  }

  Future<void> callEmergencyContact(EmergencyContact contact) async {
    if (!contact.receiveCalls) return;

    final uri = Uri.parse('tel:${contact.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch phone call');
    }
  }

  Future<void> callAmbulance() async {
    final uri = Uri.parse('tel:$_ambulanceNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch phone call');
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyHospitals() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${position.latitude},${position.longitude}'
          '&radius=5000'
          '&type=hospital'
          '&key=$_googlePlacesApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((place) {
          final location = place['geometry']['location'];
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            location['lat'],
            location['lng'],
          );
          return {
            'name': place['name'],
            'address': place['vicinity'],
            'distance': distance,
            'phone': place['formatted_phone_number'] ?? 'Not available',
            'rating': place['rating']?.toString() ?? 'Not rated',
          };
        }).toList()
          ..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get nearby hospitals: $e');
    }
  }

  Future<void> handleEmergency(
    List<EmergencyContact> contacts,
    RiskType riskType,
    String patientId,
  ) async {
    // Notify contacts based on their preferences and the risk level
    for (final contact in contacts) {
      if (contact.notifyAtRiskLevels.contains(riskType.level)) {
        if (contact.receiveSMS) {
          await sendEmergencySMS(contact, riskType, patientId);
        }
        if (contact.receiveCalls) {
          await callEmergencyContact(contact);
        }
      }
    }

    // Call ambulance for high and critical risk
    if (riskType.callAmbulance) {
      await callAmbulance();
    }
  }
} 