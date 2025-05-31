import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/heart_risk_model.tflite');
      _isInitialized = true;
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  String predictHeartCondition(double temperature, double spo2, double heartRate) {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not initialized');
    }

    // Normalize inputs (adjust these ranges based on your model's training data)
    final normalizedTemp = (temperature - 36.0) / (40.0 - 36.0); // Normalize to 0-1
    final normalizedSpo2 = (spo2 - 70.0) / (100.0 - 70.0); // Normalize to 0-1
    final normalizedHeartRate = (heartRate - 40.0) / (200.0 - 40.0); // Normalize to 0-1

    // Prepare input tensor
    var input = [normalizedTemp, normalizedSpo2, normalizedHeartRate];
    var inputShape = [1, 3]; // Batch size 1, 3 features

    // Prepare output tensor
    var outputShape = [1, 3]; // Assuming 3 classes: Low, Medium, High risk
    var outputBuffer = List.filled(3, 0.0);

    // Run inference
    _interpreter!.run(input, outputBuffer);

    // Get prediction
    var maxScore = outputBuffer[0];
    var maxIndex = 0;
    for (var i = 1; i < outputBuffer.length; i++) {
      if (outputBuffer[i] > maxScore) {
        maxScore = outputBuffer[i];
        maxIndex = i;
      }
    }

    // Return prediction based on index
    switch (maxIndex) {
      case 0:
        return 'Low Risk';
      case 1:
        return 'Medium Risk';
      case 2:
        return 'High Risk';
      default:
        return 'Unknown';
    }
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
} 