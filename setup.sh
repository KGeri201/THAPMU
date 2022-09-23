#!/bin/bash

# Install Influxdb, mosquitto, wget and python3
sudo apt-get install -y influxdb influxdb-client wget python3 python3-pip

# Install Grafana
sudo apt-get install -y adduser libfontconfig1
sudo wget https://dl.grafana.com/enterprise/release/grafana-enterprise_8.4.3_amd64.deb
sudo dpkg -i grafana-enterprise_8.4.3_amd64.deb
sudo rm -rf grafana-enterprise_8.4.3_amd64.deb

# Install python3 libraries
sudo pip3 install paho-mqtt influxdb

# Download files from github
sudo wget https://raw.githubusercontent.com/KGeri201/THAPMU/main/MQTTInfluxDBBridge.py
sudo wget -O /etc/systemd/system/ https://raw.githubusercontent.com/KGeri201/THAPMU/main/mqttinfluxdbbridge.service

sudo sed -i "s|/root|$PWD|g" /etc/systemd/system/mqttinfluxdbbridge.service

until [${#db_name} > 0]
do
  echo "Name of your database: "
  read [db_name]
done
sudo sed -i "s|INFLUXDB_DATABASE = 'db_name'|INFLUXDB_DATABASE = '$db_name'|g" MQTTInfluxDBBridge.py
until [${#db_user} > 0]
do
  echo "Name of your user: "
  read [db_user]
done
sudo sed -i "s|INFLUXDB_USER = 'db_user'|INFLUXDB_USER =  '$db_user'|g" MQTTInfluxDBBridge.py
until [${#db_pwd} <= 0 || $db_pwd != $db_pwd_ctrl]
do
  until [${#db_pwd} > 0]
  do
    echo "Password for your user: "
    read -s [db_pwd]
  done
  echo "Repeat the password: "
  read -s [db_pwd_ctrl]
  if [$db_pwd != $db_pwd_ctrl]
  then
    echo "Passwords do nto match!"
  fi
done
sudo sed -i "s|INFLUXDB_PASSWORD = 'db_pwd'|INFLUXDB_PASSWORD = '$db_pwd'|g" MQTTInfluxDBBridge.py

# Setup Influxdb
## Start influxdb service
sudo service influxdb enable
sudo service influxdb start
## Enable http endpoint
sudo sed '/#enabled = true/s/^#//' -i /etc/influxdb/influxdb.conf
## Restart influxdb service
sudo service influxdb restart
## Create Database to store measurements
## Set name of the database

#influx
##
#CREATE DATABASE mqtt_data
#USE mqtt_data
#CREATE USER mqtt WITH PASSWORD ‘mqtt’
#GRANT ALL ON mqtt_data TO mqtt

influx -execute "CREATE DATABASE '$db_name'"
influx -execute "CREATE USER '$db_user' WITH PASSWORD '$db_pwd'"
influx -execute "GRANT ALL ON '$db_name' TO '$db_user'"

sudo systemctl enable mosquitto
sudo systemctl start mosquitto
sudo systemctl enable mqttinfluxdbbridge
sudo systemctl start mqttinfluxdbbridge
sudo service grafana-server start
