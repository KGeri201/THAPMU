#!/bin/bash

if [ "$EUID" -ne 0 ]
then 
  echo "Please run as root"
  exit
fi

echo "  _____ _  _   _   ___ __  __ _   _ "
echo " |_   _| || | /_\ | _ \  \/  | | | |"
echo "   | | | __ |/ _ \|  _/ |\/| | |_| |"
echo "   |_| |_||_/_/ \_\_| |_|  |_|\___/ "

getSettings() {
  printf "\n\n--------------- SETUP ---------------\n"

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
      printf "\n\nPasswords do not match!\n\n"
      db_pwd=""
    fi
  done
}

install() {
  printf "Installing packages ...\n"
  #apt-get install -y apt-transport-https -qq
  #apt-get install -y software-properties-common wget -qq
  apt-get install -y wget --no-install-recommends -qq
  wget -q -O /usr/share/keyrings/grafana.key https://packages.grafana.com/gpg.key
  echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/enterprise/deb stable main" | tee /etc/apt/sources.list.d/grafana.list >/dev/null

  apt-get update -qq

  # Install Influxdb, mosquitto, python3 and grafana
  apt-get install -y influxdb influxdb-client mosquitto mosquitto-clients python3 python3-pip grafana-enterprise --no-install-recommends -qq

  echo "listener 1883" > /etc/mosquitto/conf.d/allow.conf && echo "allow_anonymous true" >> /etc/mosquitto/conf.d/allow.conf
} 

download() {
  printf "Downloading python script ...\n"
  if [ -f "MQTTInfluxDBBridge.py" ]
  then
    printf "Found script. Skipping ...\n"
  else
    # Download MQTTInfluxDBBridge from github
    wget -q -O MQTTInfluxDBBridge.py https://raw.githubusercontent.com/KGeri201/THAPMU/main/MQTTInfluxDBBridge.py
  fi
}

configurescript() {
  printf "Configuring script ...\n"
  # Set database, user and password
  sed -i "s|INFLUXDB_DATABASE = 'db_name'|INFLUXDB_DATABASE = '$db_name'|g" MQTTInfluxDBBridge.py
  sed -i "s|INFLUXDB_PASSWORD = 'db_pwd'|INFLUXDB_PASSWORD = '$db_pwd'|g" MQTTInfluxDBBridge.py
  sed -i "s|INFLUXDB_USER = 'db_user'|INFLUXDB_USER = '$db_user'|g" MQTTInfluxDBBridge.py
}

installRequirements() {
  printf "Installing python libraries ...\n"
  wget -q -O /tmp/requirements.txt https://raw.githubusercontent.com/KGeri201/THAPMU/main/requirements.txt
  # Install python3 libraries
  pip3 -q install -r /tmp/requirements.txt
  rm /tmp/requirements.txt
}

backupDatabase() {
  influxd backup -portable ./thapmu
}

setUpDatabase() {
  printf "Setting up the database ...\n"
  # Setup Influxdb
  ## Enable http endpoint
  sed -i -r ':a;N;$!ba;s/\[http\]\n([^\n]*)\n  # enabled = true/\[http\]\n\1\n  enabled = true/g' /etc/influxdb/influxdb.conf
  ## Start influxdb service
  systemctl enable influxdb 
  systemctl start influxdb

  if [ -d "thapmu" ]
  then
    printf "Found backup. Restoring ...\n"
    influxd restore -portable ./thapmu
  else
    influx -execute "CREATE DATABASE $db_name"
    influx -database "$db_name" -execute "CREATE USER $db_user WITH PASSWORD '$db_pwd'"
    influx -database "$db_name" -execute "GRANT ALL ON $db_name TO $db_user"
  fi

  printf "Setting up backup for the database ...\n"
  crontab -l | grep "0 0 * * * influxd backup -portable ./thapmu"
  if [ $? -ne 0 ]
  then
    echo "0 0 * * * $PWD/$0 backup" | crontab
  fi
}

startServices() {
  wget -q -O /etc/systemd/system/mqttinfluxdbbridge.service https://raw.githubusercontent.com/KGeri201/THAPMU/main/mqttinfluxdbbridge.service
  sed -i "s|/root|$PWD|g" /etc/systemd/system/mqttinfluxdbbridge.service
  #sudo systemctl enable mosquitto
  systemctl start mosquitto
  systemctl restart influxdb
  systemctl enable mqttinfluxdbbridge
  systemctl start mqttinfluxdbbridge
  systemctl start grafana-server
}

startServicesDocker() {
  /usr/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf &
  /usr/bin/influxd -config /etc/influxdb/influxdb.conf &
  /usr/sbin/grafana-server --config=/etc/grafana/grafana.ini -homepath /usr/share/grafana &
  /usr/bin/python3 /root/MQTTInfluxDBBridge.py
}

finish() {
  printf "\n##########################################################################\n"
  printf "# Visit                                                                  #\n"
  printf "#   http://localhost:3000                                                #\n"
  printf "#   username: admin                                                      #\n"
  printf "#   password: admin                                                      #\n"
  printf "# to setup Grafana to display measurements saved in the influx database. #\n"
  printf "##########################################################################\n"
}

if [ "$1" = "setup" ] || [ -z "$1" ]
then
  if [ -f "MQTTInfluxDBBridge.py" ] && [ -d "thapmu" ]
  then
    printf "Existing script and database found. Restoring ..."
  else
    getSettings
  fi
fi
if [ "$1" = "install" ] || [ -z "$1" ]
then
  printf "\n\n-------------- INSTALL --------------\n"
  install
  installRequirements
  download
fi
if [ "$1" = "setup" ] || [ -z "$1" ]
then
  printf "\n------------- CONFIGURE -------------\n"
  configurescript
  setUpDatabase
fi
if [ "$1" = "start" ] || [ -z "$1" ]
then
  printf "\n--------------- START ---------------\n"
  printf "Starting services ...\n"
  startServices
fi
if [ "$1" = "backup" ]
then
  printf "\n-------------- BACKUP ---------------\n"
  printf "Backing up all databases ...\n"
  backupDatabase
fi
printf "\n--------------- DONE ----------------\n"
if [ "$1" = "start" ] || [ -z "$1" ]
then
  finish
fi
