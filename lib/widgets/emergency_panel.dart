import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import '../models/risk_type.dart';
import '../models/emergency_contact.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyPanel extends StatefulWidget {
  final String patientId;
  final List<EmergencyContact> emergencyContacts;
  final String riskLevel;

  const EmergencyPanel({
    Key? key,
    required this.patientId,
    required this.emergencyContacts,
    required this.riskLevel,
  }) : super(key: key);

  @override
  State<EmergencyPanel> createState() => _EmergencyPanelState();
}

class _EmergencyPanelState extends State<EmergencyPanel> {
  final _emergencyService = EmergencyService();
  List<Map<String, dynamic>> _nearbyHospitals = [];
  bool _isLoadingHospitals = false;
  RiskType? _selectedRiskType;

  @override
  void initState() {
    super.initState();
    _selectedRiskType = RiskType.fromString(widget.riskLevel);
    _loadNearbyHospitals();
  }

  Future<void> _loadNearbyHospitals() async {
    if (!_selectedRiskType!.showHospitals) return;

    setState(() => _isLoadingHospitals = true);
    try {
      final hospitals = await _emergencyService.getNearbyHospitals();
      setState(() {
        _nearbyHospitals = hospitals;
        _isLoadingHospitals = false;
      });
    } catch (e) {
      setState(() => _isLoadingHospitals = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading hospitals: $e')),
      );
    }
  }

  Future<void> _handleEmergency() async {
    try {
      await _emergencyService.handleEmergency(
        widget.emergencyContacts,
        _selectedRiskType!,
        widget.patientId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling emergency: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Emergency Response',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Risk Level: ${_selectedRiskType!.name}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedRiskType!.level == RiskLevel.critical
                          ? Colors.red
                          : _selectedRiskType!.level == RiskLevel.high
                              ? Colors.orange
                              : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_selectedRiskType!.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedRiskType!.notifyContacts) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.notifications_active),
              label: const Text('Alert Emergency Contacts'),
              onPressed: _handleEmergency,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_selectedRiskType!.callAmbulance) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.local_hospital),
              label: const Text('Call Ambulance'),
              onPressed: _emergencyService.callAmbulance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_selectedRiskType!.showHospitals) ...[
            const Text(
              'Nearby Hospitals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingHospitals)
              const Center(child: CircularProgressIndicator())
            else if (_nearbyHospitals.isEmpty)
              const Text('No hospitals found nearby')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _nearbyHospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = _nearbyHospitals[index];
                    return Card(
                      child: ListTile(
                        title: Text(hospital['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hospital['address']),
                            Text(
                              'Distance: ${(hospital['distance'] / 1000).toStringAsFixed(1)} km',
                            ),
                            Text('Rating: ${hospital['rating']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () {
                            final uri = Uri.parse('tel:${hospital['phone']}');
                            launchUrl(uri);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
} 