import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  final String? userId;
  final bool? isPatient;

  const HomePage({Key? key, this.userId, this.isPatient}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String temperature = "Waiting...";
  String heartRate = "Waiting...";
  String spo2 = "Waiting...";
  String connectionStatus = "🔌 Disconnected";
  BluetoothConnection? connection;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) => getBondedDevices());
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.05,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    connection?.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    // Request all relevant Bluetooth permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  Future<void> getBondedDevices() async {
    try {
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devicesList = bondedDevices;
      });
      // Debug print
      print("Bonded devices: $_devicesList");
    } catch (e) {
      print("Error fetching bonded devices: $e");
    }
  }

  void _animatePulse() {
    _pulseController.forward().then((_) => _pulseController.reverse());
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectionStatus = "🔄 Connecting...";
    });
    try {
      BluetoothConnection newConnection = await BluetoothConnection.toAddress(
        device.address,
      );
      setState(() {
        connection = newConnection;
        connectionStatus = "🟢 Connected to ${device.name}";
      });

      connection!.input!
          .listen((data) {
        String incoming = utf8.decode(data).trim();
        for (String jsonString in incoming.split('\n')) {
          try {
            final parsed = jsonDecode(jsonString);
            if (parsed is Map<String, dynamic>) {
              setState(() {
                if (parsed.containsKey("temperature")) {
                  temperature = "${parsed["temperature"]} °F";
                  _animatePulse();
                }
                if (parsed.containsKey("heartRate")) {
                  heartRate = "${parsed["heartRate"]} bpm";
                  _animatePulse();
                }
                if (parsed.containsKey("spo2")) {
                  spo2 = "${parsed["spo2"]} %";
                  _animatePulse();
                }
              });
            }
          } catch (e) {
            // Ignore invalid JSON
          }
        }
      })
          .onDone(() {
        setState(() {
          connectionStatus = "🔴 Disconnected";
          temperature = "Waiting...";
          heartRate = "Waiting...";
          spo2 = "Waiting...";
        });
      });
    } catch (e) {
      setState(() {
        connectionStatus = "🔴 Connection Failed";
      });
    }
  }

  Widget buildDataCard(String title, String value, IconData icon, Color color) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Card(
        elevation: 6,
        shadowColor: color.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                radius: 28,
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        value,
                        key: ValueKey(value),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdownDeviceSelector() {
    if (_devicesList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No paired devices found.\nMake sure your ESP32 or other device is paired in Android Bluetooth Settings.',
          style: TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
    return DropdownButton<BluetoothDevice>(
      hint: const Text("Select a device"),
      value: _selectedDevice,
      isExpanded: true,
      items: _devicesList.map((device) {
        return DropdownMenuItem(
          value: device,
          child: Text(device.name ?? "Unknown"),
        );
      }).toList(),
      onChanged: (device) {
        if (device != null) {
          setState(() {
            _selectedDevice = device;
          });
          _connectToDevice(device);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get navigation arguments if constructor values are null
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final userId = widget.userId ?? args?['userId'] ?? '';
    final isPatient = widget.isPatient ?? args?['isPatient'] ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text((isPatient ? "Patient" : "Guardian") + " Home"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "ID: $userId",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Connection Status: $connectionStatus",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            buildDataCard(
              "🌡 Temperature",
              temperature,
              Icons.thermostat,
              Colors.deepOrange,
            ),
            buildDataCard(
              "❤ Heart Rate",
              heartRate,
              Icons.favorite,
              Colors.red,
            ),
            buildDataCard("🩸 SpO2", spo2, Icons.bloodtype, Colors.blue),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh / Reconnect"),
              onPressed: () {
                if (_selectedDevice != null) {
                  _connectToDevice(_selectedDevice!);
                } else {
                  getBondedDevices();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Previously connected devices:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            buildDropdownDeviceSelector(),
          ],
        ),
      ),
    );
  }
}