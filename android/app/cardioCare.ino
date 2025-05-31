#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <MAX30105.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// Bluetooth includes for classic SPP
#include <BluetoothSerial.h>
BluetoothSerial SerialBT;

// OLED setup
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// MAX30102 setup
MAX30105 particleSensor;

// DS18B20 temperature sensor
#define ONE_WIRE_BUS 4
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature tempSensor(&oneWire);

// Animation frame
int heartFrame = 0;

// Sensor values and buffers
float temperatureC = 0.0;
long irValue = 0;
int heartRate = 0;
int spO2 = 0;

// Buffers for 5 seconds of data (assuming 2 samples per second)
const int BUFFER_SIZE = 10; // 5 seconds * 2 samples/sec
int hrBuffer[BUFFER_SIZE];
int spO2Buffer[BUFFER_SIZE];
float tempBuffer[BUFFER_SIZE];
int bufferIndex = 0;
unsigned long lastUpdate = 0;
const unsigned long INTERVAL = 5000; // 5 seconds in milliseconds
int lastHeartRate = 0;
int lastSpO2 = 0;
float lastTemperature = 0.0;

// Function to calculate median value to reduce noise
int calculateMedian(int* buffer, int size) {
    int sorted[BUFFER_SIZE];
    for (int i = 0; i < size; i++) {
        sorted[i] = buffer[i];
    }
    for (int i = 0; i < size - 1; i++) {
        for (int j = 0; j < size - i - 1; j++) {
            if (sorted[j] > sorted[j + 1]) {
                int temp = sorted[j];
                sorted[j] = sorted[j + 1];
                sorted[j + 1] = temp;
            }
        }
    }
    return sorted[size / 2];
}

// Function to calculate median for float values
float calculateMedianFloat(float* buffer, int size) {
    float sorted[BUFFER_SIZE];
    for (int i = 0; i < size; i++) {
        sorted[i] = buffer[i];
    }
    for (int i = 0; i < size - 1; i++) {
        for (int j = 0; j < size - i - 1; j++) {
            if (sorted[j] > sorted[j + 1]) {
                float temp = sorted[j];
                sorted[j] = sorted[j + 1];
                sorted[j + 1] = temp;
            }
        }
    }
    return sorted[size / 2];
}

void setup() {
    Serial.begin(115200);
    SerialBT.begin("ESP32-Health"); // Bluetooth name, change as needed

    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("SSD1306 allocation failed");
        while (true);
    }

    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("Initializing...");
    display.display();

    if (!particleSensor.begin(Wire)) {
        Serial.println("MAX30102 not found");
        display.println("MAX30102 not found");
        display.display();
        while (true);
    }

    particleSensor.setup();
    particleSensor.setPulseAmplitudeRed(0x0A);
    particleSensor.setPulseAmplitudeGreen(0);

    tempSensor.begin();

    // Initialize buffers
    for (int i = 0; i < BUFFER_SIZE; i++) {
        hrBuffer[i] = 0;
        spO2Buffer[i] = 0;
        tempBuffer[i] = 0.0;
    }

    delay(1000);
    display.clearDisplay();
    lastUpdate = millis();
}

void loop() {
    irValue = particleSensor.getIR();

    // Collect data if IR value indicates finger presence
    if (irValue > 50000) {
        hrBuffer[bufferIndex] = random(65, 80); // Simulated heart rate
        spO2Buffer[bufferIndex] = random(95, 99); // Simulated SpO2
    } else {
        hrBuffer[bufferIndex] = 0;
        spO2Buffer[bufferIndex] = 0;
    }

    // Read temperature
    tempSensor.requestTemperatures();
    tempBuffer[bufferIndex] = tempSensor.getTempCByIndex(0);

    bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;

    // Check if 5 seconds have passed
    unsigned long currentTime = millis();
    if (currentTime - lastUpdate >= INTERVAL) {
        // Calculate median values to reduce noise
        heartRate = calculateMedian(hrBuffer, BUFFER_SIZE);
        spO2 = calculateMedian(spO2Buffer, BUFFER_SIZE);
        temperatureC = calculateMedianFloat(tempBuffer, BUFFER_SIZE);

        // Update last values
        lastHeartRate = heartRate;
        lastSpO2 = spO2;
        lastTemperature = temperatureC;

        // Print to Serial Monitor
        Serial.print("Heart Rate: ");
        Serial.print(heartRate);
        Serial.print(" bpm, SpO2: ");
        Serial.print(spO2);
        Serial.print(" %, Temperature: ");
        Serial.print(temperatureC, 1);
        Serial.println(" C");

        // Send as JSON via Bluetooth (for Flutter app)
        String json = "{\"temperature\":";
        json += String(temperatureC, 1);
        json += ",\"heartRate\":";
        json += String(heartRate);
        json += ",\"spo2\":";
        json += String(spO2);
        json += "}\n";
        SerialBT.print(json); // Send to Bluetooth SPP

        lastUpdate = currentTime;
    }

    // Display the last calculated values
    display.clearDisplay();
    display.setTextSize(2);
    display.setCursor(0, 0);
    display.print("bpm: ");
    display.print(lastHeartRate);

    display.setCursor(0, 22);
    display.print("SpO2:");
    display.print(lastSpO2);
    display.print("%");

    display.setCursor(0, 44);
    display.print("Temp:");
    display.print(lastTemperature, 1);
    display.print("C");

    drawHeart(heartFrame);
    heartFrame = (heartFrame + 1) % 2;

    display.display();
    delay(500); // Sample every 500ms (2 samples per second)
}

void drawHeart(int frame) {
    int x = 108, y = 10;
    int r = (frame == 0) ? 3 : 5;
    int offset = (frame == 0) ? 2 : 3;

    display.fillCircle(x - offset, y, r, SSD1306_WHITE);
    display.fillCircle(x + offset, y, r, SSD1306_WHITE);

    int baseY = y + r - 1;
    int tipY = y + r * 2;
    display.fillTriangle(
            x - offset - r + 1, baseY,
            x + offset + r - 1, baseY,
            x, tipY,
            SSD1306_WHITE
    );
}