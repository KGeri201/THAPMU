<p align="center"><img src="THAPMU.svg" alt="Logo" height="200"/></P>

# THAPMU
[![Docker Pulls](https://img.shields.io/docker/pulls/kgeri201/thapmu)](https://hub.docker.com/r/kgeri201/thapmu)  
THAPMU stands for **T**emerature, **H**umiditity and **A**ir **P**ressure **M**easurement **U**nit. 

## Story
I wanted to create a small, cheap and easy to make IoT sensor, that works with nearly anything,  
to monitor the temerapture and humidity levels of multiple rooms.

## Hardware
The custom PCB is a very simple power adapter to power and connect the sensor and the ESP.

## Software
It uses [ESPHome](https://esphome.io/index.html), [MQTT](https://de.wikipedia.org/wiki/MQTT), [InfluxDB](https://www.influxdata.com/) and a [script](MQTTInfluxDBBridge.py) to connect all this together.  
I found a [code](https://randomnerdtutorials.com/esp8266-nodemcu-mqtt-publish-bme280-arduino/) very similar and nearly perfect for my use.  
I only modified it a little to make it a perfect fit.    
It uses Grafana to visualize the data, but anything else can be used.

## Installation
### Docker (recomended)
Follow the Guide on [Docker Hub](https://hub.docker.com/repository/docker/kgeri201/thapmu)

### Manual
Download the thapmu.sh with wget or any other way.
```sh
wget https://raw.githubusercontent.com/KGeri201/THAPMU/main/thapmu.sh
```
And execute it as sudo
```sh
sudo ./thapmu.sh
```
#### Step by step
Grafana will be added to apt sources.  
All the needed packages will be installed  
```sh
apt-get install -y influxdb influxdb-client mosquitto mosquitto-clients python3 python3-pip grafana-enterprise
```
All the neded files will be downloaded.
```sh
wget -q -O /tmp/requirements.txt https://raw.githubusercontent.com/KGeri201/THAPMU/main/requirements.txt
wget -q -O MQTTInfluxDBBridge.py https://raw.githubusercontent.com/KGeri201/THAPMU/main/MQTTInfluxDBBridge.py
wget -q -O /etc/systemd/system/mqttinfluxdbbridge.service https://raw.githubusercontent.com/KGeri201/THAPMU/main/mqttinfluxdbbridge.service
```
Additional config will be added to mosquitto  
```sh
echo "listener 1883" > /etc/mosquitto/conf.d/allow.conf && echo "allow_anonymous true" >> /etc/mosquitto/conf.d/allow.conf
```
Python libraries will also be installed  
```sh
pip3 -q install -r /tmp/requirements.txt
```
Database will be set up, and services will be started
```sh
systemctl start mqttinfluxdbbridge
systemctl start grafana-server
systemctl restart influxdb
systemctl start mosquitto
```
Additionaly you can also enable all the services to start automatically after starting the device  
```sh
systemctl enable mosquitto
systemctl enable influxdb
systemctl enable grafana-server
systemctl enable mqttinfluxdbbridge
```

## Sensor
### Requirements
* 1 THAPMU board (fully fitted, and ready to use)
* 1 ESP01 breakout board
* 1 BME or BMP sensor
* an extra external serial adapter to flash your ESP
* an USB-C cable to power the board.

### Instructions
#### ESPHome
1. Install ESPHome on a server.
2. Go to http://ip-of-your-server:6052
3. Add new device.
4. Load the [example_esphome.conf](example_esphome.conf) and edit the values to fit your needs.  
   Make sure that the right sensor is selected and all the credentials are right.
5. Flash the code to the ESP following the guide from ESPHome

#### Legacy
1. Open the code for the ESP and change the library according to your sensor.  
```ino
#include <Adafruit_BME280.h>

// Sensor I2C
Adafruit_BME280 sensor;
```
2. Fill in your WLAN SSID and password, and the address of the MQTT broker.  
   If your MQTT broker needs credentials to authenticate, set them.  
   Also add the location and the name of the device.
```ino
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
``` 
3. Flash the ESP.  
4. Plug the board in somewhere and wait for it to connect to your WLAN and to the Server, which you previously set up (decribed under [Installation](https://github.com/KGeri201/THAPMU#installation)).
5. Go to the [Grafana](https://grafana.com/) site, hosted on your server http://ip-of-your-server:3000 and login with the default credentials.
6. Under the Configurations add the [InfluxDB](https://www.influxdata.com/products/influxdb-overview/) data source.  
  Fill in the name of the database, user and password.  
  These you have set during the setup process.
7. Make a new dashboard with the newly added InfluxDB datasource and choose the measurement.  
There are three topics:  
   - THAPMU/**LOCATION**/**NAME**/sensor/temperature/state   
   - THAPMU/**LOCATION**/**NAME**/sensor/humidity/state
   - THAPMU/**LOCATION**/**NAME**/sensor/pressure/state
8. You are up and running.  

## Credits
[HimbeersaftLP](https://github.com/HimbeersaftLP)  
[KGeri201](https://github.com/KGeri201)  

## License
[Apache License 2.0](LICENSE)

## Project status
Ready to deploy.
