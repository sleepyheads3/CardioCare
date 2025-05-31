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
}