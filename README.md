# THAPMU
THAPMU stands for **T**emerature, **H**umiditity and **A**ir **P**ressure **M**easurement **U**nit.

## Story
I wanted to monitor the temperature of several rooms and wanted to display all the measurements on one website.  
I also wanted to have it as cheap, easy to manufacture and to use as possible.  
I searched on the internet and i found a very good looking sensor and esp combo.
It was not perfect but looked promising.
I read the reviews about it and I was very disapointed.
There were only complains about the product.  
I thought, it should not be that hard to combine an esp wlan module and an measurement instrument.  
I decided for an esp-01 and for an bme280 sensor, because of his wide range of usability.
To be as easy to use as possible I wanted to add also a serial adapter to the whole thing, to make the user able to flash the esp easily, without removing it from the board.  
But it was only a dream. I wanted to use the CH340C chip as a serial adapter, but I could not find any, which I was able to have in less than two months. It was either sold out or the deliver would have taken more than my patience could handle.  
So sadly I had to make everything even cheaper and easier.  
I only gave a voltage regulator and a usb type c connector on to the board. This should not be a huge problem, because the esps needs to be flashed only once. To do this a seperate serial adapter is needed.  
(For you I even provided the Layout and Scematic of the pcb with a serial adapter. If you are lucky enough to get your hands on a CH340C, then you can make that version of this project.)

## Hardware
This is a very simple project. As a basis I took inspiration of the [SparkFun Serial Basic Breakout - CH340C and USB-C](https://www.sparkfun.com/products/15096).  
I modified the circuit and the layout to fit the requirements of the esp and the sensor. I also replaced some of the electronics with their easier to get and easier to solder counterparts.
To keep the project as simple as possible I did not integrate the esp and the sensor.
They are both normal boards to plug into the modified serial adapter.

## Software
I found a very Code very similar and nearly perfect for my usecase.
I only modified it a little to make it a perfect fit.
(Original in Credits)

## Manual
### Requirements
* 1 THAPMU board (fully fitted, and ready to use)
* 1 ESP01 breakout board
* 1 BME or BMP sensor
* If you are using the board without the integrated serial adapter,  
  then you will need an extra external serial adapter to flash your ESP
* Also an USB-C cable to power the board.

### Instructions
1. To use the sensor you will need to have a MQTT broker up and running.  
2. You will have to open the code for the ESP and fill in your WLAN SSID and password, and also the address of the MQTT broker.  
You can also add the location of the device.
```c++
#define LOCATION "LOCATION_OF_THE_DEVICE"
#define WIFI_SSID "REPLACE_WITH_YOUR_SSID"
#define WIFI_PASSWORD "REPLACE_WITH_YOUR_PASSWORD"

// Raspberri Pi Mosquitto MQTT Broker
#define MQTT_HOST IPAddress(X, X, X, X)
// For a cloud MQTT broker, type the domain name
//#define MQTT_HOST "example.com"
#define MQTT_PORT 1883
```  
&nbsp;&nbsp;&nbsp;&nbsp; Also do not forget to change the library, if you are not using a BME280.  
```c++
#include <Adafruit_BME280.h>

// Sensor I2C
Adafruit_BME280 sensor;
```
3. you have to flash the ESP.  
Using the version with the integrated serial adapter:  
&nbsp;&nbsp;&nbsp;&nbsp; You will have to remove the sensor and connect the GND Pin with the WRT (write) Pin via a jumper.  
&nbsp;&nbsp;&nbsp;&nbsp; After that you can upload the code to it.  
&nbsp;&nbsp;&nbsp;&nbsp; Remove the jumper and plug the board out then in again to reset it.  
Using your own seperate serial adapter:  
&nbsp;&nbsp;&nbsp;&nbsp; follow the instructions to your board.   
4. After that you are up and running.  
Just plug the board in somewhere and wait for it to connect to your WLAN and to the MQTT broker.

## Credits
[KGeri201](https://github.com/KGeri201)  
[randomnerdtutorials.com](https://randomnerdtutorials.com/esp8266-nodemcu-mqtt-publish-bme280-arduino/)

## License
[GNU GENERAL PUBLIC LICENSE](https://choosealicense.com/licenses/gpl-3.0/)

## Project status
In development.
