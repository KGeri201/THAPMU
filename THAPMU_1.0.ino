/*
  Original at https://RandomNerdTutorials.com/esp8266-nodemcu-mqtt-publish-bme280-arduino/
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files.
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
*/

#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <ESP8266WiFi.h>
#include <Ticker.h>
#include <AsyncMqttClient.h>
#include <Adafruit_BME280.h>

// Sensor I2C
Adafruit_BME280 sensor;

#define NAME "NAME_OF_THE_DEVICE"
#define LOCATION "LOCATION_OF_THE_DEVICE"
#define WIFI_SSID "REPLACE_WITH_YOUR_SSID"
#define WIFI_PASSWORD "REPLACE_WITH_YOUR_PASSWORD"

// Raspberri Pi Mosquitto MQTT Broker
#define MQTT_HOST IPAddress(X, X, X, X)
// For a cloud MQTT broker, type the domain name
//#define MQTT_HOST "example.com"
#define MQTT_PORT 1883
// If your MQTT broker requires authentication, set them below
#define MQTT_USER ""
#define MQTT_PASSWORD ""

/*----------------------------------------------------------------------------------------------------------------------*/

// Interval of topic updates in seconds
#define Interval 10

// Value, which will be substracted from the Temperature, due to the sensor heating itself
const double tempErrorMargin = 5.5;

// Temperature MQTT Topics
const String MQTT_PUB_TEMP = "THAPMU/" + String(LOCATION) + "/" + String(NAME)+ "sensor/temperature/state";
const String MQTT_PUB_HUM = "THAPMU/" + String(LOCATION) + "/" + String(NAME) + "sensor/humidity/state";
const String MQTT_PUB_PRES = "THAPMU/" + String(LOCATION) + "/" + String(NAME) + "sensor/pressure/state";

AsyncMqttClient mqttClient;
Ticker mqttReconnectTimer;

WiFiEventHandler wifiConnectHandler;
WiFiEventHandler wifiDisconnectHandler;
Ticker wifiReconnectTimer;

unsigned long previousMillis = 0;   // Stores last time temperature was published
const long interval = 10000;        // Interval at which to publish sensor readings

void connectToWifi() {
  Serial.println("Connecting to Wi-Fi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

void onWifiConnect(const WiFiEventStationModeGotIP& event) {
  Serial.println("Connected to Wi-Fi.");
  connectToMqtt();
}

void onWifiDisconnect(const WiFiEventStationModeDisconnected& event) {
  Serial.println("Disconnected from Wi-Fi.");
  mqttReconnectTimer.detach(); // ensure we don't reconnect to MQTT while reconnecting to Wi-Fi
  wifiReconnectTimer.once(2, connectToWifi);
}

void connectToMqtt() {
  Serial.println("Connecting to MQTT...");
  mqttClient.connect();
}

void onMqttConnect(bool sessionPresent) {
  Serial.println("Connected to MQTT.");
  Serial.print("Session present: ");
  Serial.println(sessionPresent);
}

void onMqttDisconnect(AsyncMqttClientDisconnectReason reason) {
  Serial.println("Disconnected from MQTT.");

  if (WiFi.isConnected()) {
    mqttReconnectTimer.once(2, connectToMqtt);
  }
}

/*void onMqttSubscribe(uint16_t packetId, uint8_t qos) {
  Serial.println("Subscribe acknowledged.");
  Serial.print("  packetId: ");
  Serial.println(packetId);
  Serial.print("  qos: ");
  Serial.println(qos);
}

void onMqttUnsubscribe(uint16_t packetId) {
  Serial.println("Unsubscribe acknowledged.");
  Serial.print("  packetId: ");
  Serial.println(packetId);
}

void onMqttPublish(uint16_t packetId) {
  Serial.print("Publish acknowledged.");
  Serial.print("  packetId: ");
  Serial.println(packetId);
}*/

void setup() {
  Serial.begin(115200);
  Serial.println();
  
  Wire.pins(0, 2);
  Wire.begin();
  
  // Initialize sensor 
  if (!sensor.begin(0x76)) {
    Serial.println("Could not find a valid sensor, check wiring!");
    while (1);
  }
  
  wifiConnectHandler = WiFi.onStationModeGotIP(onWifiConnect);
  wifiDisconnectHandler = WiFi.onStationModeDisconnected(onWifiDisconnect);

  mqttClient.onConnect(onMqttConnect);
  mqttClient.onDisconnect(onMqttDisconnect);
  //mqttClient.onSubscribe(onMqttSubscribe);
  //mqttClient.onUnsubscribe(onMqttUnsubscribe);
  //mqttClient.onPublish(onMqttPublish);
  mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  // If your broker requires authentication (username and password), set them below
  if (String(MQTT_USER).length() > 0 && String(MQTT_PASSWORD).length() > 0) {
    mqttClient.setCredentials(MQTT_USER, MQTT_PASSWORD);
  }
  
  connectToWifi();
}

void loop() {
  // Publish an MQTT message on topic esp/sensor/temperature
  uint16_t packetIdPub1 = mqttClient.publish(MQTT_PUB_TEMP.c_str(), 1, true, String(sensor.readTemperature()  - tempErrorMargin).c_str()); //temp = 1.8*sensor.readTemperature() + 32                        
  Serial.printf("Publishing on topic %s at QoS 1, packetId: %i ", MQTT_PUB_TEMP, packetIdPub1);

  // Publish an MQTT message on topic esp/sensor/humidity
  uint16_t packetIdPub2 = mqttClient.publish(MQTT_PUB_HUM.c_str(), 1, true, String(sensor.readHumidity()).c_str());                            
  Serial.printf("Publishing on topic %s at QoS 1, packetId: %i ", MQTT_PUB_HUM, packetIdPub2);

  // Publish an MQTT message on topic esp/sensor/pressure
  uint16_t packetIdPub3 = mqttClient.publish(MQTT_PUB_PRES.c_str(), 1, true, String(sensor.readPressure()/100.0F).c_str());                            
  Serial.printf("Publishing on topic %s at QoS 1, packetId: %i ", MQTT_PUB_PRES, packetIdPub3);
  
  // wait before reading te sensors again
  delay(Interval *1000);
}
