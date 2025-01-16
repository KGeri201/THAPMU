import re, os
from typing import NamedTuple

import paho.mqtt.client as mqtt
from influxdb_client import InfluxDBClient

INFLUXDB_ADDRESS = os.getenv('INFLUXDB_ADDRESS', 'localhost')
INFLUXDB_USER = os.getenv('INFLUXDB_USER', 'db_user')
INFLUXDB_PASSWORD = os.getenv('INFLUXDB_PASSWORD', 'db_pwd')
INFLUXDB_DATABASE = os.getenv('INFLUXDB_DATABASE', 'thapmu')
INFLUXDB_PORT = os.getenv('INFLUXDB_PORT', 8086)
INFLUXDB_ORG = os.getenv('INFLUXDB_ORG', 'thapmu')
INFLUXDB_BUCKET = os.getenv('INFLUXDB_BUCKET', 'thapmu')
INFLUXDB_TOKEN = os.getenv('INFLUXDB_TOKEN', 'my-super-secret-auth-token')

MQTT_ADDRESS = os.getenv('MQTT_ADDRESS', 'localhost')
MQTT_PORT = os.getenv('MQTT_PORT', 1883)
MQTT_USER = os.getenv('MQTT_USER', '')
MQTT_PASSWORD = os.getenv('MQTT_PASSWORD', '')
MQTT_TOPIC = os.getenv('MQTT_TOPIC', 'THAPMU/+/+/sensor/+/state')
MQTT_REGEX = os.getenv('MQTT_REGEX', 'THAPMU/([^/]+)/([^/]+)/sensor/([^/]+)/state')
MQTT_CLIENT_ID = os.getenv('MQTT_CLIENT_ID', 'MQTTInfluxDBBridge')

influx = InfluxDBClient('http://' + INFLUXDB_ADDRESS + ':' + INFLUXDB_PORT, INFLUXDB_TOKEN, INFLUXDB_ORG)
write_api = influx.write_api()

class SensorData(NamedTuple):
    location: str
    name: str
    measurement: str
    value: float

def on_connect(client, userdata, flags, rc):
    """ The callback for when the client receives a CONNACK response from the server."""
    print('Connected with result code ' + str(rc))
    client.subscribe(MQTT_TOPIC)

def _parse_mqtt_message(topic, payload):
    match = re.match(MQTT_REGEX, topic)
    if match:
        location = match.group(1)
        name = match.group(2)
        measurement = match.group(3)
        return SensorData(location, name, measurement, float(payload))
    else:
        return None

def _send_sensor_data_to_influxdb(sensor_data):
    json_body = [
        {
            'measurement': sensor_data.measurement,
            'tags': {
                'location': sensor_data.location,
                'name': sensor_data.name
            },
            'fields': {
                'value': sensor_data.value
            }
        }
    ]
    write_api.write(INFLUXDB_BUCKET, INFLUXDB_ORG, json_body)

def on_message(client, userdata, msg):
    """The callback for when a PUBLISH message is received from the server."""
    print(msg.topic + ' ' + str(msg.payload))
    sensor_data = _parse_mqtt_message(msg.topic, msg.payload.decode('utf-8'))
    if sensor_data is not None:
        _send_sensor_data_to_influxdb(sensor_data)

def main():
    mqtt_client = mqtt.Client()
    if not MQTT_USER.isspace() and bool(MQTT_USER) and not MQTT_PASSWORD.isspace() and bool(MQTT_PASSWORD):
        mqtt_client.username_pw_set(MQTT_USER, MQTT_PASSWORD)
    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message

    mqtt_client.connect(MQTT_ADDRESS, int(MQTT_PORT))
    mqtt_client.loop_forever()


if __name__ == '__main__':
    print('MQTT to InfluxDB bridge')
    main()
