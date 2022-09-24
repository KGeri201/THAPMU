FROM alpine:latest

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y wget

WORKDIR /data

RUN wget -O /usr/bin/thapmu https://raw.githubusercontent.com/KGeri201/THAPMU/main/setup.sh && \
    sed -i "s|  /usr/bin/python3 /root/MQTTInfluxDBBridge.py &|  /usr/bin/python3 $PWD/MQTTInfluxDBBridge.py &|g" /usr/bin/thapmu && \
    sed -i "s|  startServices|  startServicesDocker|g" /usr/bin/thapmu && \
    chmod +x /usr/bin/thapmu
RUN thapmu install

CMD ["thapmu", "start"]

EXPOSE 1883/tcp
EXPOSE 3000/tcp

VOLUME [ "/data" ]
