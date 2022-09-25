FROM debian:stable-slim

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y wget

WORKDIR /usr/src/app

RUN wget -q -O /usr/bin/thapmu https://raw.githubusercontent.com/KGeri201/THAPMU/main/setup.sh && \
    sed -i "s|  /usr/bin/python3 /root/MQTTInfluxDBBridge.py &|  /usr/bin/python3 $PWD/MQTTInfluxDBBridge.py &|g" /usr/bin/thapmu && \
    sed -i "s|  startServices|  startServicesDocker|g" /usr/bin/thapmu && \
    sed -i "s|  finish|  echo ''|g" /usr/bin/thapmu && \
    chmod +x /usr/bin/thapmu
    
RUN thapmu install && \
    sed -i "s|pid_file /run/mosquitto/mosquitto.pid|#pid_file /run/mosquitto/mosquitto.pid|g" /etc/mosquitto/mosquitto.conf

CMD ["thapmu", "start"]

EXPOSE 1883/tcp
EXPOSE 3000/tcp

VOLUME [ "/usr/src/app" ]
