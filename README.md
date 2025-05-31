# Heart Health Monitoring App

A Flutter application for monitoring heart health using Bluetooth sensors and machine learning.

## Features

- Real-time monitoring of vital signs (Temperature, Heart Rate, SpO2)
- Bluetooth connectivity with medical sensors
- Machine learning-based heart risk assessment
- Patient and Guardian interfaces
- Firebase integration for data storage

## Setup Instructions

1. Install Flutter and set up your development environment following the [official guide](https://flutter.dev/docs/get-started/install).

2. Install Python dependencies for model generation:
   ```bash
   pip install tensorflow numpy
   ```

3. Generate the TensorFlow Lite model:
   ```bash
   cd assets
   python generate_model.py
   ```

4. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

5. Configure Firebase:
   - Create a new Firebase project
   - Add your Android/iOS app to the project
   - Download and add the configuration files:
     - For Android: `google-services.json` to `android/app/`
     - For iOS: `GoogleService-Info.plist` to `ios/Runner/`

6. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/`
  - `screens/` - UI screens
  - `services/` - Business logic and services
  - `models/` - Data models
  - `widgets/` - Reusable widgets
- `assets/`
  - `heart_risk_model.tflite` - ML model for heart risk prediction
  - `generate_model.py` - Script to generate the ML model

## Machine Learning Model

The heart risk prediction model is a simple neural network that takes three inputs:
- Temperature (normalized to 0-1)
- SpO2 (normalized to 0-1)
- Heart Rate (normalized to 0-1)

The model outputs three classes:
- Low Risk
- Medium Risk
- High Risk

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
