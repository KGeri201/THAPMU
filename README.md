# <img src="THAPMU.svg" alt="Logo" height="200"/> THAPMU 
THAPMU stands for **T**emerature, **H**umiditity and **A**ir **P**ressure **M**easurement **U**nit.

## Story
I wanted to monitor the temperature of several rooms and wanted to display all the measurements on one website.  
I also wanted to have it as cheap, and as easy to manufacture and to use as possible.  
I searched on the internet and I found a very good looking sensor and ESP combo.
It was not perfect but looked promising.
I read the reviews about it and I was very disapointed.
I thought, it should not be that hard to combine an ESP WLan module and a measurement instrument.  
I decided for an ESP-01 and for a BME280 sensor, because of his wide range of usability.
To be as easy to use as possible I also wanted to add a serial adapter to the whole thing, to make the user able to flash the ESP easily, without the need of removing it from the board.  
But it was only a dream. I wanted to use the CH340C chip as a serial adapter, but I could not find any that I was able to have in less than two months. It was either sold out or the delivery would have taken more than my patience could handle.  
So sadly I had to make everything even cheaper and easier.  
I only put a voltage regulator and a usb type c connector on to the board. This should not be a huge problem, because the ESP needs to be flashed only once. To do this a seperate serial adapter is needed.  
(For you I even provided the layout and schematic of the PCB with a serial adapter. If you are lucky enough to get your hands on a CH340C, then you can make that version of this project.)

## Hardware
This is a very simple project. As a basis I took inspiration of the [SparkFun Serial Basic Breakout - CH340C and USB-C](https://www.sparkfun.com/products/15096).  
I modified the circuit and the layout to fit the requirements of the ESP and the sensor. I also replaced some of the electronics with their easier-to-get and easier-to-solder counterparts.
To keep the project as simple as possible I did not integrate the ESP and the sensor.
They are both normal breakout boards to plug into the modified serial adapter.

## Software
I found a [code](https://randomnerdtutorials.com/esp8266-nodemcu-mqtt-publish-bme280-arduino/) very similar and nearly perfect for my use.  
I only modified it a little to make it a perfect fit.  

## Manual
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
2. Fill in your WLAN SSID and password, and also the address of the MQTT broker. Add the location of the device if you want.
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
4. To display your data you will need to have a [MQTT broker](https://mosquitto.org/) and [grafana](https://grafana.com/) 
5. To get the data from the MQTT broker you have multiple optoions:  
    - Use [MQTT datasource plugin](https://github.com/grafana/mqtt-datasource). For that you can download [this _amazing_ docker](https://gist.github.com/HimbeersaftLP/82b2a1be7708ddcf71746cd86f2c5de0). 
    - Or you can build a [MQTT to InfluxDB Bridge](https://diyi0t.com/visualize-mqtt-data-with-influxdb-and-grafana/)
6. Make a new dashboard with MQTT as a datasource and subscribe to your topics.  
There are three topics:  
   - THAPMU/**LOCATION**/**NAME**/temperature   
   - THAPMU/**LOCATION**/**NAME**/humidity
   - THAPMU/**LOCATION**/**NAME**/pressure
7. You are up and running.  
Just plug the board in somewhere and wait for it to connect to your WLAN and to the MQTT broker.

## Credits
[Random Nerd Tutorials](https://randomnerdtutorials.com)  
[HimbeersaftLP](https://github.com/HimbeersaftLP)  
[KGeri201](https://github.com/KGeri201)  

## License
[GNU GENERAL PUBLIC LICENSE](https://choosealicense.com/licenses/gpl-3.0/)

## Project status
Nearly finished.
