#!/bin/bash

echo "##################################################"
echo "AIC8800 Wi-Fi Driver Setup Script"
echo "##################################################"

KERNEL=$(uname -r)
IS_FEDORA=$(uname -r | grep -q '\.fc[0-9]' && echo y || echo n)

# Helper: run command as root
run_root() {
	if [ "$IS_FEDORA" = "y" ]; then
		su -c "$*"
	else
		sudo sh -c "$*"
	fi
}

echo "Kernel: $KERNEL"
echo ""

# --- 1. Copy firmware ---
echo "[1/4] Copying firmware..."
run_root "cp -rf ./fw/aic8800D80 /lib/firmware/"
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to copy firmware!"
	exit 1
fi
echo "  Firmware copied to /lib/firmware/aic8800D80/"

# --- 2. Install udev rules ---
echo "[2/4] Installing udev rules..."
run_root "cp ./tools/aic.rules /etc/udev/rules.d/"
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to copy udev rules!"
	exit 1
fi
run_root "udevadm control --reload-rules"
run_root "udevadm trigger"
echo "  udev rules installed and reloaded"

# --- 3. Eject USB mass storage (switches device to WiFi mode) ---
echo "[3/4] Checking for AIC8800 USB mass storage device..."
MSC_EJECTED=0

# Method 1: check udev-created symlink
if [ -L /dev/aicudisk ]; then
	echo "  Found /dev/aicudisk — ejecting..."
	run_root "eject /dev/aicudisk" 2>/dev/null
	if [ $? -eq 0 ]; then
		MSC_EJECTED=1
		echo "  Eject succeeded"
	fi
fi

# Method 2: detect by lsusb and eject the SCSI disk
if [ "$MSC_EJECTED" = "0" ]; then
	USB_DEV=$(lsusb 2>/dev/null | grep "a69c:5721")
	if [ -n "$USB_DEV" ]; then
		# Find the SCSI disk for this USB device
		SCSI_DISK=$(lsblk -d -o NAME,MODEL 2>/dev/null | grep -i "AIC\|flash" | awk '{print $1}' | head -1)
		if [ -n "$SCSI_DISK" ]; then
			echo "  Found USB MSC on /dev/$SCSI_DISK — ejecting..."
			run_root "eject /dev/$SCSI_DISK" 2>/dev/null
			if [ $? -eq 0 ]; then
				MSC_EJECTED=1
				echo "  Eject succeeded"
			fi
		fi
	fi
fi

if [ "$MSC_EJECTED" = "1" ]; then
	echo "  Device will re-enumerate as WiFi — wait 2-3 seconds"
	sleep 3
elif [ "$MSC_EJECTED" = "0" ]; then
	echo "  No USB mass storage device found (already in WiFi mode or not connected)"
fi

# --- 4. Verify ---
echo "[4/4] Verifying installation..."
if [ -d /lib/firmware/aic8800D80 ]; then
	FW_COUNT=$(ls /lib/firmware/aic8800D80/*.bin /lib/firmware/aic8800D80/*.txt 2>/dev/null | wc -l)
	echo "  Firmware: $FW_COUNT files in /lib/firmware/aic8800D80/"
else
	echo "  WARNING: Firmware directory not found!"
fi

if [ -f /etc/udev/rules.d/aic.rules ]; then
	echo "  udev rules: installed"
else
	echo "  WARNING: udev rules not found!"
fi

echo ""
echo "##################################################"
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Load the firmware loader:  sudo modprobe aic_load_fw"
echo "  2. Load the WiFi driver:      sudo modprobe aic8800_fdrv"
echo "  3. Verify interface:          ip link show"
echo ""
echo "If wlan0 does not appear, run: dmesg | tail -20"
echo "##################################################"
