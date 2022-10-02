<p align="center"><img src="THAPMU.svg" alt="Logo" height="200"/></P>

# THAPMU
[![Docker Pulls](https://img.shields.io/docker/pulls/kgeri201/thapmu)](https://hub.docker.com/r/kgeri201/thapmu)  
THAPMU stands for **T**emerature, **H**umiditity and **A**ir **P**ressure **M**easurement **U**nit. 

## Story
I wanted to monitor the temperature of several rooms and wanted to display all the measurements on one website.  
I also wanted to have it as cheap, and as easy to manufacture and to use as possible.  
I searched on the internet and I found a very good looking sensor and ESP combo.
It was not perfect but looked promising.
I read the reviews about it and I was very disapointed.
I thought, it should not be that hard to combine an ESP WLan module and a measurement instrument.  
I decided for an ESP-01 and for a BME280 sensor, because of his wide range of usability and accuracy.
To be as easy to use as possible I also wanted to add a serial adapter to the whole thing, to make the user able to flash the ESP easily, without the need of removing it from the board.  
But it was only a dream. I wanted to use the CH340C chip as a serial adapter, but I could not find any that I was able to have in less than two months. It was either sold out or the delivery would have taken more than my patience could handle.  
So sadly I had to make everything even cheaper and easier.  
I only put a voltage regulator and a usb type c connector on to the board. This should not be a huge problem, because the ESP needs to be flashed only once. To do this a seperate serial adapter is needed.  
(I also provided the layout and schematic of the PCB with a serial adapter. If you are lucky enough to get your hands on a CH340C, then you can make that version of this project.)

## Hardware
This is a very simple project. As a basis I took inspiration of the [SparkFun Serial Basic Breakout - CH340C and USB-C](https://www.sparkfun.com/products/15096).  
I modified the circuit and the layout to fit the requirements of the ESP and the sensor. I also replaced some of the electronics with their easier-to-get and easier-to-solder counterparts.
To keep the project as simple as possible I did not integrate the ESP and the sensor.
They are both normal breakout boards to plug into the modified serial adapter. (Hint: ESP sits on the top side, Sensor is on the bottom.)

## Software
I found a [code](https://randomnerdtutorials.com/esp8266-nodemcu-mqtt-publish-bme280-arduino/) very similar and nearly perfect for my use.  
I only modified it a little to make it a perfect fit.  

## Installation
### Docker
Follow the Guide on [Docker Hub](https://hub.docker.com/repository/docker/kgeri201/thapmu)

### Manual
Download the setup.sh with wget or any other way.
```sh
wget https://raw.githubusercontent.com/KGeri201/THAPMU/main/setup.sh
```
And execute it as sudo
```sh
sudo ./setup.sh
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
```
echo "listener 1883" > /etc/mosquitto/conf.d/allow.conf && echo "allow_anonymous true" >> /etc/mosquitto/conf.d/allow.conf
```
Python libraries will also be installed  
```
pip3 -q install -r /tmp/requirements.txt
```
Database will be set up, and services will be started
```
systemctl start mqttinfluxdbbridge
systemctl start grafana-server
systemctl restart influxdb
systemctl start mosquitto
```
Additionaly you can also enable all the services to start automatically after starting the device  
```
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
* If you are using the board without the integrated serial adapter,  
  then you will need an extra external serial adapter to flash your ESP
* Also an USB-C cable to power the board.

### Instructions
1. Open the code for the ESP and change the library according to your sensor.  
```ino
#include <Adafruit_BME280.h>

// Sensor I2C
Adafruit_BME280 sensor;
```
2. Fill in your WLAN SSID and password, and also the address of the MQTT broker.   
Add the location and the name of the device.
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
``` 
3. Flash the ESP.  
    - Using the version with the integrated serial adapter:  
      - Remove the sensor and connect the GND pin with the WRT (write) pin via a jumper.  
      - Upload the code.  
      - Remove the jumper and plug the board out then in again to reset it.  
    - Using your own seperate serial adapter:  
      - follow the instructions of your board. 
4. Plug the board in somewhere and wait for it to connect to your WLAN and to the Server, which you previously set up (decribed under [Installation](https://github.com/KGeri201/THAPMU#installation)).
5. Go to the [Grafana](https://grafana.com/) site, hosted on your server http://ip-of-your-server:3000 and login with the default credentials.
6. Under the Configurations add the [InfluxDB](https://www.influxdata.com/products/influxdb-overview/) data source.  
  Fill in the name of the database, user and password.  
  These you have set during the setup process.
7. Make a new dashboard with the newly added InfluxDB datasource and choose the measurement.  
There are three topics:  
   - THAPMU/**LOCATION**/**NAME**/temperature   
   - THAPMU/**LOCATION**/**NAME**/humidity
   - THAPMU/**LOCATION**/**NAME**/pressure
8. You are up and running.  

## Credits
[HimbeersaftLP](https://github.com/HimbeersaftLP)  
[KGeri201](https://github.com/KGeri201)  

## License
[GNU GENERAL PUBLIC LICENSE](LICENSE)

## Project status
Ready to deploy.
