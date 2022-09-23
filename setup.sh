#!/bin/bash

until [ ${#db_name} -gt 0 ]
do 
  read -p "Name of your database: " db_name
done
until [ ${#db_user} -gt 0 ]
do
  read -p "Name of your user: " db_user
done
until [ ${#db_pwd} -gt 0 ] && [ $db_pwd == $db_pwd_ctrl ]
do
  until [ ${#db_pwd} -gt 0 ]
  do
    read -sp "Password for your user: " db_pwd
  done
  echo ""
  read -sp "Repeat the password: " db_pwd_ctrl
  if [ $db_pwd != $db_pwd_ctrl ]
  then
    printf "\nPasswords do not match!"
    db_pwd=""
  fi
done

echo ""

sudo printf "\nInstalling packages...\n"
#sudo apt-get install -y apt-transport-https -qq
#sudo apt-get install -y software-properties-common wget -qq
sudo apt-get install -y wget -qq
sudo wget -q -O /usr/share/keyrings/grafana.key https://packages.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/enterprise/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list >/dev/null

# Install Influxdb, mosquitto, wget, python3 and grafana
sudo apt-get install -y influxdb influxdb-client mosquitto mosquitto-clients wget python3 python3-pip grafana-enterprise -qq

printf "Downloading files...\n"
# Download files from github
sudo wget -q -O requirements.txt https://raw.githubusercontent.com/KGeri201/THAPMU/main/requirements.txt
sudo wget -q -O MQTTInfluxDBBridge.py https://raw.githubusercontent.com/KGeri201/THAPMU/main/MQTTInfluxDBBridge.py
sudo wget -q -O /etc/systemd/system/mqttinfluxdbbridge.service https://raw.githubusercontent.com/KGeri201/THAPMU/main/mqttinfluxdbbridge.service

sudo sed -i "s|/root|$PWD|g" /etc/systemd/system/mqttinfluxdbbridge.service

sudo sed -i "s|INFLUXDB_DATABASE = 'db_name'|INFLUXDB_DATABASE = '$db_name'|g" MQTTInfluxDBBridge.py
sudo sed -i "s|INFLUXDB_USER = 'db_user'|INFLUXDB_USER = '$db_user'|g" MQTTInfluxDBBridge.py
sudo sed -i "s|INFLUXDB_PASSWORD = 'db_pwd'|INFLUXDB_PASSWORD = '$db_pwd'|g" MQTTInfluxDBBridge.py

printf "Installing python libraries...\n"
# Install python3 libraries
sudo pip3 -q install -r requirements.txt

printf "Setting up the database...\n"
# Setup Influxdb
## Start influxdb service
#sudo systemctl enable influxdb 
sudo systemctl start influxdb 
## Enable http endpoint
sudo sed '/#enabled = true/s/^#//' -i /etc/influxdb/influxdb.conf
## Restart influxdb service

## Create Database to store measurements
## Set name of the database

#influx
#CREATE DATABASE "$db_name"
#USE "$db_name"
#CREATE USER "$db_user" WITH PASSWORD "$db_pwd"
#GRANT ALL ON "$db_name" TO "$db_user"
#EXIT

sudo influx -execute 'CREATE DATABASE "$db_name"; USE "$db_name"; CREATE USER "$db_user" WITH PASSWORD "$db_pwd"; GRANT ALL ON "$db_name" TO "$db_user"'

printf "Starting services...\n"
#sudo systemctl enable mosquitto
sudo systemctl start mosquitto
sudo systemctl restart influxdb
sudo systemctl enable mqttinfluxdbbridge
sudo systemctl start mqttinfluxdbbridge
sudo service grafana-server start

printf "Done\n"
