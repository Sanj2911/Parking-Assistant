#include <WiFi.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <FirebaseESP32.h>

// Replace with your WiFi credentials
#define WIFI_SSID "Replace"
#define WIFI_PASSWORD "Replace"

#define API_KEY "Replace firebase api"
#define DATABASE_URL "Replace firebase project url"

// Ultrasonic sensor pins
#define TRIG_PIN 33
#define ECHO_PIN 32

// Firebase data object
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
long duration;
int distance;

void setup() {
    delay(1000); // 1-second delay

    Serial.begin(115200);

    // Set up the ultrasonic sensor pins
    pinMode(TRIG_PIN, OUTPUT);
    pinMode(ECHO_PIN, INPUT);

    // Connect to WiFi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.println("Connecting to WiFi...");
    while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(300);
    }
    Serial.println("\nConnected with IP: ");
    Serial.println(WiFi.localIP());
    Serial.println();

    config.api_key = API_KEY;
    config.database_url = DATABASE_URL;

    if (Firebase.signUp(&config, &auth, "", "")) {
        Serial.println("SignUp OK");
        signupOK = true;
    } else {
        Serial.printf("SignUp Failed: %s\n", config.signer.signupError.message.c_str());
    }
  
    config.token_status_callback = tokenStatusCallback; // Monitor token status
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
}

void loop() {
    if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0)) {
        sendDataPrevMillis = millis();

        // Trigger the ultrasonic sensor
        digitalWrite(TRIG_PIN, LOW);
        delayMicroseconds(2);
        digitalWrite(TRIG_PIN, HIGH);
        delayMicroseconds(10);
        digitalWrite(TRIG_PIN, LOW);

        // Read the echo pin
        duration = pulseIn(ECHO_PIN, HIGH);
        // Calculate the distance in cm
        distance = duration * 0.034 / 2;

        // Update distance in Firebase
        if (Firebase.RTDB.setInt(&fbdo, "/Sensor/ultrasonic_distance", distance)) {
            Serial.print("Distance: ");
            Serial.print(distance);
            Serial.println(" cm - successfully saved to: " + fbdo.dataPath());
        } else {
            Serial.println("Failed to save distance data: " + fbdo.errorReason());
        }
    }
}
