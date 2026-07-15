#!/bin/bash

echo "##################################################"
echo "AIC8800 Wi-Fi Driver Uninstall Script"
echo "##################################################"

KERNEL=$(uname -r)
IS_FEDORA=$(uname -r | grep -q '\.fc[0-9]' && echo y || echo n)

run_root() {
	if [ "$IS_FEDORA" = "y" ]; then
		su -c "$*"
	else
		sudo sh -c "$*"
	fi
}

echo "Kernel: $KERNEL"
echo ""

# --- 1. Unload modules if loaded ---
echo "[1/5] Unloading modules..."
sudo modprobe -r aic8800_fdrv 2>/dev/null
sudo modprobe -r aic_load_fw 2>/dev/null
sudo rmmod aic8800_fdrv 2>/dev/null
sudo rmmod aic_load_fw 2>/dev/null
echo "  Done"

# --- 2. Remove modules ---
echo "[2/5] Removing kernel modules..."
MODDIR="/lib/modules/$KERNEL/kernel/drivers/net/wireless/aic8800"
run_root "rm -rf $MODDIR"
echo "  Removed $MODDIR"

# Also remove stale SDIO module directory if present
SDIO_MODDIR="/lib/modules/$KERNEL/kernel/drivers/net/wireless/aic8800_sdio"
if [ -d "$SDIO_MODDIR" ]; then
	run_root "rm -rf $SDIO_MODDIR"
	echo "  Removed stale SDIO directory: $SDIO_MODDIR"
fi

# --- 3. Remove firmware ---
echo "[3/5] Removing firmware..."
run_root "rm -rf /lib/firmware/aic8800D80"
run_root "rm -rf /lib/firmware/aic8800DC"
echo "  Removed /lib/firmware/aic8800D80/"
echo "  Removed /lib/firmware/aic8800DC/"

# --- 4. Remove udev rules ---
echo "[4/5] Removing udev rules..."
run_root "rm -f /etc/udev/rules.d/aic.rules"
run_root "udevadm control --reload-rules"
echo "  Done"

# --- 5. Update module dependencies ---
echo "[5/5] Updating module dependencies..."
sudo depmod -a "$KERNEL" 2>/dev/null
echo "  Done"

echo ""
echo "##################################################"
echo "Uninstall complete!"
echo "##################################################"
