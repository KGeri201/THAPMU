FROM python:3-alpine

ENV INFLUXDB_ADDRESS "db"
ENV INFLUXDB_USER "db_user"
ENV INFLUXDB_PASSWORD "db_pwd_123"
ENV INFLUXDB_DATABASE "thapmu"
ENV INFLUXDB_ORG "thapmu"
ENV INFLUXDB_BUCKET "thapmu"
ENV INFLUXDB_TOKEN "my-super-secret-auth-token"
ENV INFLUXDB_PORT 8086

ENV MQTT_ADDRESS "mqtt"
ENV MQTT_PORT 1883
ENV MQTT_USER ""
ENV MQTT_PASSWORD ""
ENV MQTT_TOPIC "THAPMU/+/+/sensor/+/state"
ENV MQTT_REGEX "THAPMU/([^/]+)/([^/]+)/sensor/([^/]+)/state"
ENV MQTT_CLIENT_ID "MQTTInfluxDBBridge"

RUN apk update && apk upgrade --available

WORKDIR /usr/src/app

COPY requirements.txt /tmp/
COPY MQTTInfluxDBBridge.py ./

RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

RUN rm /tmp/requirements.txt

ENTRYPOINT ["/usr/local/bin/python3", "MQTTInfluxDBBridge.py"]
