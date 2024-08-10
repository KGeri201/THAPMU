# THAPMU

Guide to deploy project as a docker container.  
To run the container, MQTT and InfluxDB are required.
To visuallize the data we use grafana.

## Docker Compose
```yml
version: '3.3'
services:
  mqtt:
    container_name: mosquitto
    restart: unless-stopped
    ports:
      - 1883:1883
    volumes:
      - ./mosquitto:/mosquitto/config
    image: eclipse-mosquitto:latest

  db:
    container_name: influxdb
    restart: unless-stopped
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=db_user
      - DOCKER_INFLUXDB_INIT_PASSWORD=db_pwd_123
      - DOCKER_INFLUXDB_INIT_ORG=thapmu
      - DOCKER_INFLUXDB_INIT_BUCKET=thapmu
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=my-super-secret-auth-token
    volumes:
      - ./influxdb2:/var/lib/influxdb2
    image: influxdb:latest

  grafana:
    container_name: grafana
    restart: unless-stopped
    ports:
      - 3000:3000
    volumes:
      - grafana_data:/var/lib/grafana
    image: grafana/grafana:latest

  thapmu:
    container_name: thapmu
    restart: unless-stopped
    environment:
      - INFLUXDB_ORG=thapmu
      - INFLUXDB_BUCKET=thapmu
      - INFLUXDB_TOKEN=my-super-secret-auth-token
    depends_on:
      - mqtt
      - db
    image: kgeri201/thapmu:latest

volumes:
  grafana_data: {}
```

## Installation
1. Install docker compose.  
2. Dowload the docker-compose.yml and edit it.
```sh
wget https://raw.githubusercontent.com/KGeri201/THAPMU/main/docker-compose.yml
```
Make sure to set all the necessary environment variables.
| Variable | Description | Default Value |
|-----------------------------------|--------------------------------------------------------------------------------|--------|
| INFLUXDB_ADDRESS | The address of the Influxdb database. (Optional) | "db" |
| INFLUXDB_ORG | The name to set for the system's initial organization. |"thapmu" |
| INFLUXDB_BUCKET | The name to set for the system's initial bucket. | "thapmu" |
| INFLUXDB_TOKEN | The authentication token to associate with the system's initial super-user. | "my-super-secret-auth-token" |
| INFLUXDB_PORT | The port influxdb listens on. (Optional) | 8086 |
| MQTT_ADDRESS | The address of the Influxdb database. (Optional) | "mqtt" |
| MQTT_PORT | The port the mqtt broker listens on. (Optional) | 1883 |
| MQTT_USER | MQTT user. (Optional) | "" |
| MQTT_PASSWORD | MQTT password. (Optional) | "" |
| MQTT_TOPIC | The MQTT Topic. (Optional) | "THAPMU/+/+/sensor/+/state" |
| MQTT_REGEX | Regex to match the MQTT Topic. (Optional) | "THAPMU/([^/]+)/([^/]+)/sensor/([^/]+)/state" |
| MQTT_CLIENT_ID | ID of the MQTT Client (Optional) | "MQTTInfluxDBBridge" |
<!--- | INFLUXDB_USER | The username to set for the system's initial super-user. (Optional) | "db_user" | --->
<!--- | INFLUXDB_PASSWORD | The password to set for the system's inital super-user. (Optional) | "db_pwd_123" | --->
<!--- | INFLUXDB_DATABASE |The name to set for the system's initial database. (Optional) | "thapmu" | --->

3. Create config file ```mosquitto.conf``` inside the directory mounted inside the mosquitto container.
```conf
listener 1883
allow_anonymous true
```

4. Start all containers
```sh
docker compose up -d
```
