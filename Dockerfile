FROM debian:stable-slim

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y ca-certificates cron --no-install-recommends

COPY thapmu.sh /usr/local/bin/thapmu

WORKDIR /usr/src/app

VOLUME ["/usr/src/app"]

RUN sed -i -e 's/\r$//' /usr/local/bin/thapmu && \
    sed -i "s|  /usr/bin/python3 /root/MQTTInfluxDBBridge.py|  /usr/bin/python3 $PWD/MQTTInfluxDBBridge.py|g" /usr/local/bin/thapmu && \
    sed -i "s|  systemctl start influxdb|  /usr/bin/influxd -config /etc/influxdb/influxdb.conf &>/dev/null &|g" /usr/local/bin/thapmu && \
    sed -i "s|  finish|  printf 'Everything is up and running.\n'|g" /usr/local/bin/thapmu && \
    sed -i "s|  startServices|  startServicesDocker|g" /usr/local/bin/thapmu && \
    chmod +x /usr/local/bin/thapmu
    
RUN thapmu install && \
    sed -i "s|pid_file /run/mosquitto/mosquitto.pid|#pid_file /run/mosquitto/mosquitto.pid|g" /etc/mosquitto/mosquitto.conf

CMD ["thapmu", "start"]

EXPOSE 1883/tcp
EXPOSE 3000/tcp
