import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Shows a dialog to select a paired Bluetooth device.
/// Returns the selected [BluetoothDevice], or null if none selected.
Future<BluetoothDevice?> showBluetoothDevicePicker(BuildContext context) async {
  // Fetch the list of bonded (paired) Bluetooth devices
  List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();

  if (devices.isEmpty) {
    // If no devices are paired, show a SnackBar message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No paired Bluetooth devices found.")),
      );
    }
    return null;
  }

  // Show a dialog with the list of devices to pick from
  return showDialog<BluetoothDevice>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: const Text('Select Bluetooth Device'),
        children: devices
            .map(
              (device) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, device),
            child: Text(
              '${device.name ?? "Unknown"} (${device.address})',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        )
            .toList(),
      );
    },
  );
}