<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  final String userId;
  final bool isPatient;

  const HomePage({
    Key? key,
    required this.userId,
    required this.isPatient,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String temperature = "Waiting...";
  String spo2 = "Waiting...";
  String bpm = "Waiting...";
  String predictionResult = "Risk: --";
  String connectionStatus = "🔌 Disconnected";
  BluetoothConnection? connection;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;

  Interpreter? _interpreter;
  bool isLoading = false;

  final TextEditingController ageController = TextEditingController();
  String? selectedSex; // "M" or "F"

  @override
  void initState() {
    super.initState();
    requestBluetooth();
    _loadModel();
  }

  Future<void> requestBluetooth() async {
    await FlutterBluetoothSerial.instance.requestEnable();
    getBondedDevices();
  }

  Future<void> getBondedDevices() async {
    try {
      List<BluetoothDevice> bondedDevices =
      await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devicesList = bondedDevices;
      });
    } catch (e) {
      print("Error fetching bonded devices: $e");
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/heart_risk_model.tflite');
    } catch (e) {
      setState(() {
        predictionResult = "Model Load Failed";
      });
      print("Failed to load model: $e");
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectionStatus = "🔄 Connecting...";
    });
    try {
      BluetoothConnection newConnection =
      await BluetoothConnection.toAddress(device.address);
      setState(() {
        connection = newConnection;
        connectionStatus = "🟢 Connected to ${device.name}";
      });

      connection!.input!.listen((data) {
        String incoming = utf8.decode(data).trim();
        for (String jsonString in incoming.split('\n')) {
          try {
            final parsed = jsonDecode(jsonString);
            if (parsed is Map<String, dynamic>) {
              setState(() {
                if (parsed.containsKey("temperature")) {
                  temperature = "${parsed["temperature"]}";
                }
                if (parsed.containsKey("heartRate")) {
                  bpm = "${parsed["heartRate"]}";
                }
                if (parsed.containsKey("spo2")) {
                  spo2 = "${parsed["spo2"]}";
                }
              });
              // Run prediction if age and sex are entered and all device data is available
              _autoPredictIfReady();
            }
          } catch (_) {}
        }
      }).onDone(() {
        setState(() {
          connectionStatus = "🔴 Disconnected";
          temperature = "Waiting...";
          spo2 = "Waiting...";
          bpm = "Waiting...";
          predictionResult = "Risk: --";
        });
      });
    } catch (e) {
      setState(() {
        connectionStatus = "🔴 Connection Failed";
      });
    }
  }

  void _autoPredictIfReady() {
    // Only predict if all required fields are available
    if (_interpreter == null) {
      setState(() {
        predictionResult = "Model Load Failed";
      });
      return;
    }
    if (temperature == "Waiting..." ||
        spo2 == "Waiting..." ||
        bpm == "Waiting...") {
      setState(() {
        predictionResult = "Waiting for device data...";
      });
      return;
    }
    // Age and sex from user input
    String? ageText = ageController.text;
    String? sexInput = selectedSex;
    if (ageText.isEmpty || sexInput == null) {
      setState(() {
        predictionResult = "Enter Age and Select Sex";
      });
      return;
    }

    double? temp = double.tryParse(temperature);
    double? ox = double.tryParse(spo2);
    double? hr = double.tryParse(bpm);
    double? age = double.tryParse(ageText);
    double sexVal = (sexInput == "M" || sexInput == "Male") ? 1.0 : 0.0;

    if (temp == null || ox == null || hr == null || age == null) {
      setState(() {
        predictionResult = "Invalid data";
      });
      return;
    }

    var input = [
      [temp, ox, hr, age, sexVal]
    ];
    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    try {
      _interpreter!.run(input, output);
      int pred = output[0][0].round();
      String label = "Unknown";
      if (pred == 0) {
        label = "Normal";
      } else if (pred == 1) {
        label = "Abnormal";
      } else if (pred == 2) {
        label = "At Risk";
      }
      setState(() {
        predictionResult = "Risk: $label ($pred)";
      });
    } catch (e) {
      setState(() {
        predictionResult = "Prediction Error";
      });
    }
  }

  Widget buildDropdownDeviceSelector() {
    if (_devicesList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No paired devices found.\nPair your ESP32 in Bluetooth Settings.',
          style: TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
    return DropdownButton<BluetoothDevice>(
      hint: const Text("Select device"),
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
  void dispose() {
    ageController.dispose();
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = widget.isPatient;
    return Scaffold(
      appBar: AppBar(
        title: Text(isPatient ? "Patient Home" : "Guardian Home"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    "Latest Device Readings",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  buildDropdownDeviceSelector(),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.thermostat, color: Colors.deepOrange),
                    title: const Text("Temperature"),
                    trailing: Text("$temperature °C",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: const Text("Heart Rate"),
                    trailing: Text("$bpm bpm",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bloodtype, color: Colors.blue),
                    title: const Text("SpO2"),
                    trailing: Text("$spo2 %",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const Divider(),
                  // Age input
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(
                      labelText: "Age (years)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(_autoPredictIfReady),
                  ),
                  const SizedBox(height: 16),
                  // Sex selection
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Sex",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wc),
                    ),
                    value: selectedSex,
                    items: const [
                      DropdownMenuItem(value: "M", child: Text("Male")),
                      DropdownMenuItem(value: "F", child: Text("Female")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSex = value;
                        _autoPredictIfReady();
                      });
                    },
                    validator: (v) => v == null ? "Select sex" : null,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.purple.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital, color: Colors.purple),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              predictionResult,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    connectionStatus,
                    style: TextStyle(
                      color: connectionStatus.startsWith("🟢")
                          ? Colors.green
                          : connectionStatus.startsWith("🔄")
                          ? Colors.orange
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
=======
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../services/ml_service.dart';
import '../widgets/emergency_panel.dart';
import '../screens/emergency_contacts_page.dart';
import '../models/emergency_contact.dart';
import '../models/risk_type.dart';
import '../services/database_service.dart';

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
  String heartRisk = "Waiting for data...";
  String connectionStatus = "🔌 Disconnected";
  BluetoothConnection? connection;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;
  final MLService _mlService = MLService();
  bool _isModelInitialized = false;
  final DatabaseService _dbService = DatabaseService();
  List<EmergencyContact> _emergencyContacts = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) => getBondedDevices());
    _initializeMLModel();
    _loadEmergencyContacts();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.05,
    );
  }

  Future<void> _loadEmergencyContacts() async {
    if (widget.userId == null) return;
    try {
      final contacts = await _dbService.getEmergencyContacts(widget.userId!);
      setState(() {
        _emergencyContacts = contacts;
      });
    } catch (e) {
      print('Error loading emergency contacts: $e');
    }
  }

  Future<void> _initializeMLModel() async {
    try {
      await _mlService.initialize();
      setState(() {
        _isModelInitialized = true;
      });
    } catch (e) {
      print('Error initializing ML model: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    connection?.dispose();
    _mlService.dispose();
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
              double? temp, hr, sp;
              
              setState(() {
                if (parsed.containsKey("temperature")) {
                  temp = double.tryParse(parsed["temperature"].toString());
                  temperature = "${parsed["temperature"]} °F";
                  _animatePulse();
                }
                if (parsed.containsKey("heartRate")) {
                  hr = double.tryParse(parsed["heartRate"].toString());
                  heartRate = "${parsed["heartRate"]} bpm";
                  _animatePulse();
                }
                if (parsed.containsKey("spo2")) {
                  sp = double.tryParse(parsed["spo2"].toString());
                  spo2 = "${parsed["spo2"]} %";
                  _animatePulse();
                }
              });

              // Update heart risk prediction if all values are available and valid
              if (temp != null && hr != null && sp != null) {
                _updateHeartRisk(temp!, hr!, sp!);
              }
            }
          } catch (e) {
            print('Error processing data: $e');
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

  void _updateHeartRisk(double temp, double hr, double sp) {
    if (!_isModelInitialized) return;

    try {
      final prediction = _mlService.predictHeartCondition(temp, sp, hr);
      setState(() {
        heartRisk = prediction;
      });

      // Show emergency panel for high risk
      if (prediction == 'High Risk') {
        _showEmergencyPanel();
      }
    } catch (e) {
      print('Error predicting heart risk: $e');
    }
  }

  void _showEmergencyPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EmergencyPanel(
            patientId: widget.userId ?? '',
            emergencyContacts: _emergencyContacts,
            riskLevel: heartRisk,
          ),
        ),
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyContactsPage(
                    patientId: userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Patient ID",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userId,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Connection Status: $connectionStatus",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            buildDataCard(
              "Temperature",
              temperature,
              Icons.thermostat,
              Colors.deepOrange,
            ),
            buildDataCard(
              "Heart Rate",
              heartRate,
              Icons.favorite,
              Colors.red,
            ),
            buildDataCard(
              "SpO2",
              spo2,
              Icons.bloodtype,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 6,
              shadowColor: Colors.purple.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Heart Risk Assessment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      heartRisk,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: heartRisk == "High Risk"
                            ? Colors.red
                            : heartRisk == "Medium Risk"
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
>>>>>>> 1af2eb8667a4b1c17d7920c43c21974f62325751
}