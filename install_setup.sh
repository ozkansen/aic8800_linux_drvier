#!/bin/bash

echo "##################################################"
echo "AIC Wi-Fi driver Setup Files script"
echo "2023.03.09 v1.1.0"
echo "##################################################"

Main_version=`uname -r |awk -F'.' '{print $1}'`
Minor_version=`uname -r |awk -F'.' '{print $2}'`

echo "Authentication requested [root] for setup:"
if [ "`uname -r |grep fc`" == " " ]; then
	sudo sh -c "cp -rf ./fw/aic8800D80 /lib/firmware/"; Error=$?
	if [ $Error -ne 0 ]; then
		echo "ERROR: Firmware kopyalanamadi!"
		exit 1
	fi
	sudo sh -c "cp ./tools/aic.rules /etc/udev/rules.d"; Error=$?
	if [ $Error -ne 0 ]; then
		echo "ERROR: udev rules kopyalanamadi!"
		exit 1
	fi
	sudo sh -c "udevadm trigger"; Error=$?
	if [ $Error -ne 0 ]; then
		echo "WARNING: udev trigger basarisiz oldu"
	fi
	sudo sh -c "udevadm control --reload-rules"; Error=$?
	if [ $Error -ne 0 ]; then
		echo "WARNING: udev reload basarisiz oldu"
	fi
	if [ -L /dev/aicudisk ]; then
		sudo sh -c "eject /dev/aicudisk"; Error=$?
	fi
else
	su -c "cp -rf ./fw/aic8800D80 /lib/firmware/"; Error=$?
	if [ $Error -ne 0 ]; then
		echo "ERROR: Firmware kopyalanamadi!"
		exit 1
	fi
	su -c "cp ./tools/aic.rules /etc/udev/rules.d"; Error=$?
	if [ $Error -ne 0 ]; then
		echo "ERROR: udev rules kopyalanamadi!"
		exit 1
	fi
	su -c "udevadm trigger"; Error=$?
	if [ $Error -ne 0 ]; then
		echo "WARNING: udev trigger basarisiz oldu"
	fi
	su -c "udevadm control --reload-rules"; Error=$?
	if [ $Error -ne 0 ]; then
		echo "WARNING: udev reload basarisiz oldu"
	fi
	if [ -L /dev/aicudisk ]; then
		su -c "eject /dev/aicudisk"; Error=$?
	fi
fi

echo "##################################################"
echo "The Setup Script is completed !"
echo "##################################################"
