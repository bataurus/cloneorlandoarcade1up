#!/bin/bash

# Global variables
ROOT_DIR="/home/pi/arcade1up"
SCRIPTS_DIR="${ROOT_DIR}/scripts"
GITHUB_REPO="https://github.com:bataurus/cloneorlandoarcade1up.git"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "*** Installing prerequisites ***"
echo

apt-get update
apt-get -y install git python-pip
install RPi.GPIO

echo

if [ ! -d ${ROOT_DIR} ];
then
  # Create root directory
  mkdir -p ${ROOT_DIR}
  # Clone repo
  git clone ${GITHUB_REPO} ${ROOT_DIR}
  # Set dummy user to be able to stash/pull
  git -C ${ROOT_DIR} config user.name "someone"
  git -C ${ROOT_DIR} config user.email "someone@retropie.com"
  echo -e "${GREEN}Repo cloned at ${ROOT_DIR} ${NC}"
else
  git -C ${ROOT_DIR} stash
  git -C ${ROOT_DIR} pull
  git -C ${ROOT_DIR} stash pop
  echo -e "${GREEN}Repo already cloned, updated instead${NC}"
fi

echo
echo "*** Prerequisites have been installed ***"
echo

RC_LOCAL_FILE="/etc/rc.local"
POWER_SCRIPT_CMD="python $SCRIPTS_DIR/power.py &"
VOLUME_SCRIPT_CMD="python $SCRIPTS_DIR/volume.py &"

grep -q -F "$POWER_SCRIPT_CMD" "$RC_LOCAL_FILE"
if [ $? -ne 0 ]; 
then
  read -p "Press 'Y' to configure the POWER SWITCH script: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    sed -i.bakp "/^exit 0/i $POWER_SCRIPT_CMD" "$RC_LOCAL_FILE"
    echo "Power switch script has been configured"
    echo -e "${RED}*** Make sure your power button is connected to pins 5 & 6 ***${NC}"
  else
    echo "Skipped power switch configuration"
  fi  
else 
  echo "Power switch script is already configured"
  echo -e "${RED}*** Make sure your power button is connected to pins 5 & 6 ***${NC}"
fi

echo

grep -q -F "$VOLUME_SCRIPT_CMD" "$RC_LOCAL_FILE"
if [ $? -ne 0 ]; 
then
  read -p "Press 'Y' to configure the VOLUME SWITCH script: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    sed -i.bakv "/^exit 0/i $VOLUME_SCRIPT_CMD" "$RC_LOCAL_FILE"
    echo "Volume switch script has been configured"
    echo -e "${RED} *** Default pin configuration is LOW=18 and MAX=16 ***"
    echo -e "${RED} *** Edit config/config.ini file to change pin and volume level defaults ***${NC}"
  else
    echo "Skipped volume switch configuration"
  fi
else
  echo "Volume switch script is already configured"
  echo -e "${RED} *** Default pin configuration is LOW=18 and MAX=16 ***"
  echo -e "${RED} *** Edit config/config.ini file to change pin and volume level defaults ***${NC}"
fi

echo

systemctl -all | grep arcade1up-relay.service > /dev/null
if [ $? -ne 0 ]; 
then
  read -p "Press 'Y' to configure the POWER RELAY script: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    systemctl enable /home/pi/arcade1up/scripts/arcade1up-relay.service
    systemctl daemon-reload
    echo "Power relay script has been configured"
    echo -e "${RED} *** Default pin configuration is PIN 22 ***"
    echo -e "${RED} *** Edit config/config.ini file to change pin default number ***${NC}"
  else
    echo "Skipped power relay configuration"
  fi
else
  echo "Power relay script is already configured"
  echo -e "${RED} *** Default pin configuration is PIN 22 ***"
  echo -e "${RED} *** Edit config/config.ini file to change pin default number ***${NC}"
fi

echo
echo "If you need to change defult pin values in config/config.ini do that NOW. Otherwise, reboot."
echo
echo -e "${GREEN}     sudo reboot${NC}"
echo
echo "Finished setup"
