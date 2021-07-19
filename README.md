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
But it was only a dream. I wanted to use the CH340C chip as a serial adapter, but I could not find any, which I was able to have in less than two months. It was either sold out or the deliver would have taken more than my patience could handle. So sadly I had to make everything even cheaper and easier. I only gave a voltage regulator and a usb type c connector on to the board. This should not be a huge problem, because the esps needs to be flashed only once. To to this a seperate serial adapter is needed. (For you I provided even the Layout and Scematic of the pcb with a serial adapter. If you are lucky enough to get your hands on a CH340C, then you can make that version of this project.)

## Hardware
This is a very simple project. As a basis I took inspiration of the [SparkFun Serial Basic Breakout - CH340C and USB-C](https://www.sparkfun.com/products/15096).
I modified the circuit and the layout to fit the requirements of the esp and the sensor.
To keep the project as simple as possible I did not integrate the esp and the sensor.
They are both normal boards to plug into the modified serial adapter.

## Software
I designed the software in Arduino IDE.
There are two versions. One for the sensors (slaves) and one for a brain unit (master), which is hosting a mqtt server and reading and displaying the data of all the sensors. 

## Credits
[KGeri201](https://github.com/KGeri201)

## License
[GNU GENERAL PUBLIC LICENSE](https://choosealicense.com/licenses/gpl-3.0/)

## Project status
In development.
