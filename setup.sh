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
  getCredentials
  db_user=$username
  db_pwd=$passwd
  use_mqtt_auth="X"
  until [[ $use_mqtt_auth = "y" ]] || [[ $use_mqtt_auth = "Y" ]] || [[ $use_mqtt_auth = "n" ]] || [[ $use_mqtt_auth = "N" ]] || [[ $use_mqtt_auth = "" ]]
  do 
    if [ -f "$PWD/mqtt_password.txt" ]
    then
      use_mqtt_auth="Y"
    else
      read -p "Do you want to use authentication to connect to MQTT (y/N): " -n 1 use_mqtt_auth
      printf "\n"
    fi
  done
  if [[ $use_mqtt_auth = "y" ]] || [[ $use_mqtt_auth = "Y" ]]
  then
    if [ -f "$PWD/mqtt_password.txt" ]
    then
      printf "\nCredentials found for MQTT.\n"
    else
      getCredentials
      mqtt_user=$username
      mqtt_pwd=$passwd
      echo "$mqtt_user:$mqtt_pwd" > $PWD/mqtt_password.txt
      mosquitto_passwd -U $PWD/mqtt_password.txt
    fi
  fi
}

getCredentials() {
  username=""
  passwd=""
  until [ ${#username} -gt 0 ]
  do
    read -p "Name of your user: " username
  done
  until [ ${#passwd} -gt 0 ] && [ $passwd == $passwd_ctrl ]
  do
    until [ ${#passwd} -gt 0 ]
    do
      read -sp "Password for your user: " passwd
    done
    printf "\n"
    read -sp "Repeat the password: " passwd_ctrl
    if [ $passwd != $passwd_ctrl ]
    then
      printf "\n\nPasswords do not match!\n\n"
      passwd=""
    fi
  done
  printf "\n"
}

install() {
  printf "Installing packages ...\n"
  apt-get install -y wget --no-install-recommends -qq
  wget -q -O /usr/share/keyrings/grafana.key https://packages.grafana.com/gpg.key
  echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/enterprise/deb stable main" | tee /etc/apt/sources.list.d/grafana.list >/dev/null

  apt-get update -qq

  # Install Influxdb, mosquitto, python3 and grafana
  apt-get install -y influxdb influxdb-client mosquitto mosquitto-clients python3 python3-pip grafana-enterprise --no-install-recommends -qq

  echo "listener 1883" > /etc/mosquitto/conf.d/allow.conf 
  echo "allow_anonymous true" > /etc/mosquitto/conf.d/mqtt_auth.conf
} 

download() {
  printf "Downloading python script ...\n"
  if [ -f "MQTTInfluxDBBridge.py" ]
  then
    printf "Found script. Skipping ...\n"
  else
    # Download MQTTInfluxDBBridge from github
    wget -q https://raw.githubusercontent.com/KGeri201/THAPMU/main/MQTTInfluxDBBridge.py
  fi
}

configurescript() {
  printf "Configuring script ...\n"
  # Set database, user and password
  sed -i "s|INFLUXDB_DATABASE = 'db_name'|INFLUXDB_DATABASE = '$db_name'|g" MQTTInfluxDBBridge.py
  sed -i "s|INFLUXDB_PASSWORD = 'db_pwd'|INFLUXDB_PASSWORD = '$db_pwd'|g" MQTTInfluxDBBridge.py
  sed -i "s|INFLUXDB_USER = 'db_user'|INFLUXDB_USER = '$db_user'|g" MQTTInfluxDBBridge.py

  if [[ $use_mqtt_auth = "y" ]] || [[ $use_mqtt_auth = "Y" ]]
  then
    sed -i "s|MQTT_USER = ''|MQTT_USER = '$mqtt_user'|g" MQTTInfluxDBBridge.py
    sed -i "s|MQTT_PASSWORD = ''|MQTT_PASSWORD = '$mqtt_pwd'|g" MQTTInfluxDBBridge.py
    sed -i "s|    #mqtt_client.username_pw_set(MQTT_USER, MQTT_PASSWORD)|    mqtt_client.username_pw_set(MQTT_USER, MQTT_PASSWORD)|g" MQTTInfluxDBBridge.py
  fi
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
  systemctl start mqttinfluxdbbridge
  systemctl start grafana-server
  systemctl restart influxdb
  systemctl start mosquitto
}

startServicesDocker() {
  /usr/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf &>/dev/null &
  /usr/bin/influxd -config /etc/influxdb/influxdb.conf &>/dev/null &
  /usr/sbin/grafana-server --config=/etc/grafana/grafana.ini -homepath /usr/share/grafana &>/dev/null &
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

setUpMqtt() {
  if [ -f "$PWD/mqtt_password.txt" ]
  then
    echo "allow_anonymous false" > /etc/mosquitto/conf.d/mqtt_auth.conf
    echo "password_file $PWD/mqtt_password.txt" >> /etc/mosquitto/conf.d/mqtt_auth.conf
  else
    echo "allow_anonymous true" > /etc/mosquitto/conf.d/mqtt_auth.conf
  fi
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
  printf "\n-------------- INSTALL --------------\n"
  install
  installRequirements
  download
fi
if [ "$1" = "setup" ] || [ -z "$1" ]
then
  printf "\n------------- CONFIGURE -------------\n"
  configurescript
  setUpDatabase
  setUpMqtt
fi
if [ "$1" = "setup" ] || [ "$1" = "start" ] || [ -z "$1" ]
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
if [ "$1" = "install" ]
then
  printf "Execute ** thapmu setup ** to setup the database and the mqtt server.\n"
fi
