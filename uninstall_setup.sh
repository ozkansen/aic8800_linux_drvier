#!/bin/bash
################################################################################
#			clean files
################################################################################
echo "Clean aic8800 wifi driver setup files!"
echo "Authentication requested [root] for clean:"
if ! uname -r | grep -q '\.fc[0-9]'; then
	  sudo sh -c "rm -rf /lib/firmware/aic8800D80/"; Error=$?
	  sudo sh -c "rm /etc/udev/rules.d/aic.rules"; Error=$?
	  sudo sh -c "udevadm control --reload-rules"; Error=$?
else
	  su -c "rm -rf /lib/firmware/aic8800D80/"; Error=$?
	  su -c "rm /etc/udev/rules.d/aic.rules"; Error=$?
	  su -c "udevadm control --reload-rules"; Error=$?
fi

echo "The Uninstall Setup Script is completed!"
