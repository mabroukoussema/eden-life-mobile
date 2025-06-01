#include <WiFi.h>
#include <FirebaseESP32.h>
#include <BH1750.h>
#include <Wire.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Preferences.h>
#include <time.h>

// WiFi credentials
#define WIFI_SSID "DESKTOP-SE7J32I 1806"
#define WIFI_PASSWORD "1234567899"

// Firebase credentials
#define FIREBASE_HOST "https://final-base-99d49-default-rtdb.firebaseio.com/"
#define FIREBASE_AUTH "AIzaSyAlPOCHioQb57BXRpgD_0f8i7r1WcHuN7A"

// NTP Server configuration
#define NTP_SERVER "pool.ntp.org"
#define GMT_OFFSET_SEC 3600   // Ajuster selon votre fuseau horaire
#define DAYLIGHT_OFFSET_SEC 0

// JSN-SR04 Ultrasonic Sensor configuration
#define TRIG_PIN 26
#define ECHO_PIN 25
#define SOUND_SPEED 0.034
#define TRIG_PULSE_DURATION_US 10
#define MAX_DISTANCE 400
#define MIN_DISTANCE 2

// DS18B20 configuration
#define ONE_WIRE_BUS 4
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature tempSensor(&oneWire);

// BH1750 configuration
BH1750 lightMeter;

// SEN0161 pH Sensor configuration
#define PH_SENSOR_PIN 35
#define PH_CALIBRATION_SAMPLES 50
float PH_SLOPE = 10.65;
float PH_OFFSET =-4.77;

// Firebase objects
FirebaseData firebaseData;
FirebaseConfig firebaseConfig;
FirebaseAuth firebaseAuth;
Preferences preferences;

// Timing variables
const unsigned long SENSOR_INTERVAL = 5000;
const unsigned long WIFI_RECONNECT_INTERVAL = 10000;
unsigned long lastSensorRead = 0;
unsigned long lastWiFiCheck = 0;

// Rolling average buffer with improved precision
#define ROLLING_AVG_SIZE 15
float distanceBuffer[ROLLING_AVG_SIZE] = {0};
float luxBuffer[ROLLING_AVG_SIZE] = {0};
float temperatureBuffer[ROLLING_AVG_SIZE] = {0};
float pHBuffer[ROLLING_AVG_SIZE] = {0};
int bufferIndex = 0;
bool bufferFilled = false;

// Kalman filter variables for distance
float distanceEstimate = 0;
float distanceErrorEstimate = 1;
float distanceMeasurementError = 3;

// Kalman filter variables for temperature
float tempEstimate = 0;
float tempErrorEstimate = 1;
float tempMeasurementError = 0.5;

// Function prototypes
void connectWiFi();
void initTime();
float readDistance();
float readLightIntensity();
float readTemperature();
float readPH();
void calibratePH();
void saveDataLocally(float distance, float lux, float temperature, float pH, time_t timestamp);
void sendToFirebase(float distance, float lux, float temperature, float pH, time_t timestamp);
float applyKalmanFilter(float measurement, float &estimate, float &errorEstimate, float measurementError);
time_t getCurrentTimestamp();

void setup() {
    Serial.begin(115200);
    while (!Serial);

    // Initialize ultrasonic sensor pins
    pinMode(TRIG_PIN, OUTPUT);
    pinMode(ECHO_PIN, INPUT);
    digitalWrite(TRIG_PIN, LOW);

    // Initialize I2C and BH1750
    Wire.begin();
    if (!lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE_2)) {
        Serial.println("BH1750 initialization failed!");
        while (1);
    }
    Serial.println("BH1750 initialized");

    // Initialize DS18B20
    tempSensor.begin();
    if (tempSensor.getDeviceCount() == 0) {
        Serial.println("DS18B20 not detected!");
        while (1);
    }
    tempSensor.setResolution(12); // Highest resolution
    Serial.println("DS18B20 initialized");

    // Initialize pH sensor
    pinMode(PH_SENSOR_PIN, INPUT);
    calibratePH();
    Serial.println("pH sensor initialized");

    // Connect to WiFi
    connectWiFi();

    // Initialize time
    initTime();

    // Configure Firebase
    firebaseConfig.host = FIREBASE_HOST;
    firebaseConfig.signer.tokens.legacy_token = FIREBASE_AUTH;
    Firebase.begin(&firebaseConfig, &firebaseAuth);
    Firebase.reconnectWiFi(true);
    Firebase.setReadTimeout(firebaseData, 1000 * 60);
    Firebase.setwriteSizeLimit(firebaseData, "tiny");
    Serial.println("Firebase initialized");

    // Initialize Preferences for local storage
    preferences.begin("sensorData", false);
}

void connectWiFi() {
    if (WiFi.status() == WL_CONNECTED) return;

    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("Connecting to WiFi");
    unsigned long startAttempt = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 15000) {
        delay(500);
        Serial.print(".");
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi connected");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("\nWiFi connection failed");
    }
}

void initTime() {
    configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC, NTP_SERVER);
    Serial.print("Waiting for NTP time sync");
    time_t now = time(nullptr);
    while (now < 8 * 3600 * 2) { // Wait for valid time (after 1970)
        delay(500);
        Serial.print(".");
        now = time(nullptr);
    }
    Serial.println("");
    struct tm timeinfo;
    gmtime_r(&now, &timeinfo);
    Serial.print("Current time: ");
    Serial.println(asctime(&timeinfo));
}

time_t getCurrentTimestamp() {
    time_t now;
    time(&now);
    return now;
}

float applyKalmanFilter(float measurement, float &estimate, float &errorEstimate, float measurementError) {
    float kalmanGain = errorEstimate / (errorEstimate + measurementError);
    estimate = estimate + kalmanGain * (measurement - estimate);
    errorEstimate = (1 - kalmanGain) * errorEstimate;
    return estimate;
}

float readDistance() {
    const int numReadings = 7;
    float validReadings[numReadings];
    int validCount = 0;

    for (int i = 0; i < numReadings; i++) {
        digitalWrite(TRIG_PIN, LOW);
        delayMicroseconds(2);
        digitalWrite(TRIG_PIN, HIGH);
        delayMicroseconds(TRIG_PULSE_DURATION_US);
        digitalWrite(TRIG_PIN, LOW);

        long duration = pulseIn(ECHO_PIN, HIGH, 30000);
        float soundSpeed = adjustSoundSpeed(readTemperature());
        float distance = (duration == 0) ? -1 : duration * soundSpeed / 2;

        if (distance >= MIN_DISTANCE && distance <= MAX_DISTANCE) {
            validReadings[validCount++] = distance;
        }
        delay(20);
    }

    if (validCount == 0) return -1;

    // Sort readings and take median
    for (int i = 0; i < validCount - 1; i++) {
        for (int j = i + 1; j < validCount; j++) {
            if (validReadings[i] > validReadings[j]) {
                float temp = validReadings[i];
                validReadings[i] = validReadings[j];
                validReadings[j] = temp;
            }
        }
    }

    float medianDistance = validReadings[validCount / 2];
    return applyKalmanFilter(medianDistance, distanceEstimate, distanceErrorEstimate, distanceMeasurementError);
}

float readLightIntensity() {
    const int numReadings = 5;
    float sum = 0;
    int validReadings = 0;

    for (int i = 0; i < numReadings; i++) {
        float lux = lightMeter.readLightLevel();
        if (lux >= 0 && lux <= 100000) {
            sum += lux;
            validReadings++;
        }
        delay(10);
    }

    if (validReadings == 0) return -1;
    return sum / validReadings;
}

float readTemperature() {
    const int numReadings = 3;
    float sum = 0;
    int validReadings = 0;

    for (int i = 0; i < numReadings; i++) {
        tempSensor.requestTemperatures();
        float tempC = tempSensor.getTempCByIndex(0);
        if (tempC >= -55 && tempC <= 125) {
            sum += tempC;
            validReadings++;
        }
        delay(10);
    }

    if (validReadings == 0) return -999;
    float avgTemp = sum / validReadings;
    return applyKalmanFilter(avgTemp, tempEstimate, tempErrorEstimate, tempMeasurementError);
}

void calibratePH() {
    // This should be replaced with actual calibration procedure
    // For now we'll just read some samples to stabilize
    float sum = 0;
    for (int i = 0; i < PH_CALIBRATION_SAMPLES; i++) {
        sum += analogRead(PH_SENSOR_PIN);
        delay(10);
    }
    // Dummy calibration - replace with real calibration
    PH_SLOPE = 3.5;
    PH_OFFSET = 0.0;
}

float readPH() {
    const int numSamples = 20;
    float sumVoltage = 0;
    
    for (int i = 0; i < numSamples; i++) {
        int rawValue = analogRead(PH_SENSOR_PIN);
        float voltage = (rawValue / 4095.0) * 3.3;
        sumVoltage += voltage;
        delay(5);
    }
    
    float avgVoltage = sumVoltage / numSamples;
    static float filteredVoltage = avgVoltage;
    const float alpha = 0.05; // Very low for slow changes
    filteredVoltage = alpha * avgVoltage + (1 - alpha) * filteredVoltage;
    
    float pHValue = PH_SLOPE * filteredVoltage + PH_OFFSET;
    pHValue = compensatePH(pHValue, readTemperature())+3.20;
    
    if (pHValue < 0 || pHValue > 14) return -1;
    return pHValue;
}

float adjustSoundSpeed(float temperature) {
    if (temperature == -999) return SOUND_SPEED;
    return 331.3 * sqrt(1 + temperature / 273.15) / 10000.0;
}

float compensatePH(float pH, float temperature) {
    if (temperature == -999) return pH;
    return pH / (1.0 + 0.0092 * (temperature - 25.0)); // More accurate compensation
}

void saveDataLocally(float distance, float lux, float temperature, float pH, time_t timestamp) {
    FirebaseJson json;
    json.set("distance", distance);
    json.set("lux", lux);
    json.set("temperature", temperature);
    json.set("pH", pH);
    json.set("timestamp", String(timestamp));
    
    String key = "/sensorData/" + String(timestamp);
    preferences.putString(key.c_str(), json.raw());
}

void sendToFirebase(float distance, float lux, float temperature, float pH, time_t timestamp) {
    if (!Firebase.ready()) {
        saveDataLocally(distance, lux, temperature, pH, timestamp);
        return;
    }

    FirebaseJson json;
    json.set("distance", distance);
    json.set("lux", lux);
    json.set("temperature", temperature);
    json.set("pH", pH);
    json.set("timestamp", String(timestamp));

    String path = "/sensorData/" + String(timestamp);
    if (Firebase.setJSON(firebaseData, path, json)) {
        Serial.println("Data sent to Firebase");
    } else {
        Serial.print("Firebase error: ");
        Serial.println(firebaseData.errorReason());
        saveDataLocally(distance, lux, temperature, pH, timestamp);
    }
}

void loop() {
    // WiFi reconnection
    if (millis() - lastWiFiCheck >= WIFI_RECONNECT_INTERVAL) {
        if (WiFi.status() != WL_CONNECTED) {
            Serial.println("Reconnecting to WiFi...");
            connectWiFi();
        }
        lastWiFiCheck = millis();
    }

    // Sensor reading
    if (millis() - lastSensorRead >= SENSOR_INTERVAL) {
        time_t currentTimestamp = getCurrentTimestamp();
        
        float distance = readDistance();
        float lux = readLightIntensity();
        float temperature = readTemperature();
        float pH = readPH();

        // Update rolling buffers
        distanceBuffer[bufferIndex] = distance;
        luxBuffer[bufferIndex] = lux;
        temperatureBuffer[bufferIndex] = temperature;
        pHBuffer[bufferIndex] = pH;
        
        bufferIndex = (bufferIndex + 1) % ROLLING_AVG_SIZE;
        if (bufferIndex == 0) bufferFilled = true;
        
        // Calculate averages
        int count = bufferFilled ? ROLLING_AVG_SIZE : bufferIndex;
        float avgDistance = 0, avgLux = 0, avgTemp = 0, avgPH = 0;
        int validDistance = 0, validLux = 0, validTemp = 0, validPH = 0;
        
        for (int i = 0; i < count; i++) {
            if (distanceBuffer[i] >= 0) { avgDistance += distanceBuffer[i]; validDistance++; }
            if (luxBuffer[i] >= 0) { avgLux += luxBuffer[i]; validLux++; }
            if (temperatureBuffer[i] != -999) { avgTemp += temperatureBuffer[i]; validTemp++; }
            if (pHBuffer[i] >= 0) { avgPH += pHBuffer[i]; validPH++; }
        }
        
        avgDistance = validDistance > 0 ? avgDistance / validDistance : -1;
        avgLux = validLux > 0 ? avgLux / validLux : -1;
        avgTemp = validTemp > 0 ? avgTemp / validTemp : -999;
        avgPH = validPH > 0 ? avgPH / validPH : -1;

        // Print results
        Serial.println("\n--- Sensor Readings ---");
        Serial.printf("Timestamp: %ld\n", currentTimestamp);
        Serial.printf("Distance: %.2f cm\n", avgDistance);
        Serial.printf("Light: %.2f lx\n", avgLux);
        Serial.printf("Temperature: %.2f °C\n", avgTemp);
        Serial.printf("pH: %.2f\n", avgPH);

        // Send to Firebase or save locally
        if (WiFi.status() == WL_CONNECTED) {
            sendToFirebase(avgDistance, avgLux, avgTemp, avgPH, currentTimestamp);
        } else {
            saveDataLocally(avgDistance, avgLux, avgTemp, avgPH, currentTimestamp);
        }

        lastSensorRead = millis();
    }
}