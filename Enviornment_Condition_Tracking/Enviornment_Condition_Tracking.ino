#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <DHT.h>
#include <HTTPClient.h>
#include <TinyGPS++.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>
#include <SoftwareSerial.h>
#include <math.h>
#include <HardwareSerial.h>
#include "PMS.h"

#define WIFI_SSID "xxxxxxx"
#define WIFI_PASSWORD "xxxxxxx"
#define API_KEY "xxxxxxx"
#define DATABASE_URL "https://xxxxxxxx/"
#define DHT22_PIN  4
#define RXD2 16
#define TXD2 17
#define MIC_PIN 35

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
DHT dht22(DHT22_PIN, DHT22);
String GOOGLE_SCRIPT_ID = "xxxxxxxxxxx";
HardwareSerial neogps(1);
HardwareSerial pmsSerial(1);
PMS pms(pmsSerial);
PMS::DATA data;
TinyGPSPlus gps;
Adafruit_MPU6050 mpu;

unsigned long sendDataPrevMillis = 0;
int count = 0;
bool signupOK = false;
const int buzzer = 27;
float ax_offset = 0, ay_offset = 0, az_offset = 0;

void calibrateMPU6050() {
  Serial.println("Calibrating MPU6050...");
  sensors_event_t a, g, temp;

  for (int i = 0; i < 100; i++) {
    mpu.getEvent(&a, &g, &temp);
    ax_offset += a.acceleration.x;
    ay_offset += a.acceleration.y;
    az_offset += a.acceleration.z;
    delay(10);
  }

  ax_offset /= 100;
  ay_offset /= 100;
  az_offset /= 100;
  az_offset -= 9.8; 
  Serial.println("Calibration complete!");
}

void setup() {
  Serial.begin(115200);
  dht22.begin();
  neogps.begin(9600, SERIAL_8N1, RXD2, TXD2);
  pmsSerial.begin(9600, SERIAL_8N1, 19, 18);
  pms.passiveMode();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  pinMode(buzzer, OUTPUT);

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("ok");
    signupOK = true;
  } else {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) {
      delay(10);
    }
  }
  Serial.println("MPU6050 Found!");

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  calibrateMPU6050();

  Serial.println("Setup complete!");

}

void loop() {
  boolean newData = false;
  unsigned long start = millis();
  unsigned long currentMillis = millis();
  while (millis() - start < 1000) {
    while (neogps.available()) {
      if (gps.encode(neogps.read())) {
        newData = true;
      }
    }
  }

  if (newData) {
    newData = false;
    Serial.print("Satellites: ");
    Serial.println(gps.satellites.value());
  } else {
    Serial.println("No new data is received.");
  }

  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  int samples = 100;
  long sum = 0;

  for (int i = 0; i < samples; i++) {
    int val = analogRead(MIC_PIN);
    sum += (val - 2048) * (val - 2048); 
    delayMicroseconds(200); 
  }

  pms.wakeUp();
  pms.requestRead();

  if (pms.readUntil(data)) {
    Serial.println(data.PM_AE_UG_1_0);
    Serial.println(data.PM_AE_UG_2_5);
    Serial.println(data.PM_AE_UG_10_0);
  }
  else {
    Serial.println("No data.");
  }

  float Temperature = dht22.readTemperature();
  float Humidity = dht22.readHumidity();
  float Latitude = gps.location.lat();
  float Longitude = gps.location.lng();
  float Satellites = gps.satellites.value();
  float ax = a.acceleration.x - ax_offset;
  float ay = a.acceleration.y - ay_offset;
  float az = a.acceleration.z - az_offset;
  float Decibel = 20 * log10(sqrt(sum / samples));
  float PM1 = data.PM_AE_UG_1_0;
  float PM2_5 = data.PM_AE_UG_2_5;
  float PM10 = data.PM_AE_UG_10_0;

  float Pitch = atan2(ax, sqrt(pow(ay, 2) + pow(az, 2))) * 180 / PI;
  float Roll = atan2(ay, sqrt(pow(ax, 2) + pow(az, 2))) * 180 / PI;
  Pitch = round(Pitch * 10) / 10.0;
  Roll = round(Roll * 10) / 10.0;
  Decibel = round(Decibel * 100) / 100.0;

  Serial.print(Latitude);
  Serial.println(Longitude);
  Serial.println(Satellites);

  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();
    if (Firebase.RTDB.setInt(&fbdo, "/x/Temperature", Temperature)) {
      Serial.print("Temperature: ");
      Serial.print(Temperature);
      Serial.print(" || ");
    } 
    if (Firebase.RTDB.setInt(&fbdo, "/x/Humidity", Humidity)) {
      Serial.print("Humidity: ");
      Serial.println(Humidity);
    }
    if (Firebase.RTDB.setInt(&fbdo, "/x/Latitude", Latitude)) {
      Serial.print("Latitude: ");
      Serial.print(Latitude);
      Serial.print(" || ");
    }
    if (Firebase.RTDB.setInt(&fbdo, "/x/Longitude", Longitude)) {
      Serial.print("Longitude: ");
      Serial.println(Longitude);
    }
    if (Firebase.RTDB.setInt(&fbdo, "/x/Pitch", Pitch)) {
      Serial.print("Pitch: ");
      Serial.print(Pitch);
      Serial.print(" || ");
    }
    if (Firebase.RTDB.setInt(&fbdo, "/x/Roll", Roll)) {
      Serial.print("Roll: ");
      Serial.println(Roll);
    }
    // if (Firebase.RTDB.setInt(&fbdo, "/Site_1/Satellites", Satellites)) {
    //   Serial.print("Satellites: ");
    //   Serial.println(Satellites);
    // }
    if (Firebase.RTDB.setInt(&fbdo, "/x/Decibel", Decibel)) {
      Serial.print("Decibel: ");
      Serial.println(Decibel);
    }
    if (Firebase.RTDB.setInt(&fbdo, "/x/PM1", PM1)) {
      Serial.print("PM1.0: ");
      Serial.println(PM1);
    }
    if (Firebase.RTDB.setInt(&fbdo, "/x/PM2_5", PM2_5)) {
      Serial.print("PM2.5: ");
      Serial.println(PM2_5);
    }
    if (Firebase.RTDB.setInt(&fbdo, "/x/PM10", PM10)) {
      Serial.print("PM10: ");
      Serial.println(PM10);
    }

    // print_speed();
    static unsigned long googleSheetPrevMillis = 0;
    if (currentMillis - googleSheetPrevMillis > 30000 || googleSheetPrevMillis == 0) {
    googleSheetPrevMillis = currentMillis;

    String param;
    param  = "temperature=" + String(Temperature);
    param += "&humidity=" + String(Humidity);
    param += "&pitch=" + String(Pitch);
    param += "&roll=" + String(Roll);
    param += "&decibel=" + String(Decibel);
    param += "&pm1=" + String(PM1);
    param += "&pm2_5=" + String(PM2_5);
    param += "&pm10=" + String(PM10);
    write_to_google_sheet(param);
    }
  }

  digitalWrite(buzzer, LOW);
  if (Pitch > 5.0 || Pitch < -5.0 || Roll > 5.0 || Roll < -5.0) {
    digitalWrite(buzzer, HIGH);
  }
  if (Temperature >= 33) {
    digitalWrite(buzzer, HIGH);
  }
  if (Humidity > 85) {
    digitalWrite(buzzer, HIGH);
  }
  if (Decibel > 85) {
    digitalWrite(buzzer, HIGH);
  }
  if (PM1 > 35) {
    digitalWrite(buzzer, HIGH);
  }
  if (PM2_5 > 50) {
    digitalWrite(buzzer, HIGH);
  }
  if (PM10 > 100) {
    digitalWrite(buzzer, HIGH);
  }

  int no_helmet = 0;
  if (Firebase.RTDB.getInt(&fbdo, "/Site_1/no_helmet")) {
    no_helmet = fbdo.intData();
    Serial.print("no_helmet: ");
    Serial.println(no_helmet);
    if (no_helmet > 0) {
    digitalWrite(buzzer, HIGH);
    }
  } else {
  Serial.print("Failed to get no_helmet: ");
  Serial.println(fbdo.errorReason());
  }
  

  delay(10);

}

void write_to_google_sheet(String params) {
   HTTPClient http;
   String url="https://script.google.com/macros/s/"+GOOGLE_SCRIPT_ID+"/exec?"+params;
   //Serial.print(url);
    Serial.println("Postring GPS data to Google Sheet");

    //starts posting data to google sheet
    http.begin(url.c_str());
    http.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);
    int httpCode = http.GET();  
    Serial.print("HTTP Status Code: ");
    Serial.println(httpCode);

    //getting response from google sheet
    String payload;
    if (httpCode > 0) {
        payload = http.getString();
        Serial.println("Payload: "+payload);     
    }

    http.end();
}
