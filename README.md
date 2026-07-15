# AIC8800 Linux Driver

Linux driver for the AIC8800 Wi-Fi/BT chipset, supporting USB and SDIO interfaces.

## Supported Platforms

| Platform | Board | Kernel | Status |
|----------|-------|--------|--------|
| Orange Pi 5 | RK3588S | Armbian Debian Trixie (6.1.115-vendor / 6.18.33-current) | Tested |
| Ubuntu/Debian | x86_64 / ARM64 | 5.x - 6.x | Supported |
| Fedora | x86_64 | 5.x - 6.x | Supported |

## Requirements

### Debian / Ubuntu / Armbian

```bash
sudo apt install build-essential linux-headers-$(uname -r)
```

### Fedora

```bash
sudo dnf install kernel-devel kernel-headers gcc make git
```

## Building

```bash
git clone https://github.com/goecho/aic8800_linux_drvier.git
cd aic8800_linux_drvier
make
```

This builds two kernel modules:

- `aic_load_fw.ko` — Bluetooth and firmware loader
- `aic8800_fdrv.ko` — Wi-Fi driver

## Installation

### Automatic

```bash
sudo make install
```

This will:

1. Copy both `.ko` files to `/lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800/`
2. Run `depmod`
3. Copy firmware files to `/lib/firmware/aic8800D80/`
4. Install udev rules to `/etc/udev/rules.d/aic.rules`
5. Reload udev

### Manual

```bash
# Copy firmware
sudo cp -rf fw/aic8800D80 /lib/firmware/

# Copy udev rules
sudo cp tools/aic.rules /etc/udev/rules.d/
sudo udevadm trigger
sudo udevadm control --reload-rules

# Copy modules
sudo mkdir -p /lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800
sudo cp drivers/aic8800/aic_load_fw/aic_load_fw.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800/
sudo cp drivers/aic8800/aic8800_fdrv/aic8800_fdrv.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800/
sudo depmod -a $(uname -r)
```

## Loading the Driver

Load modules in order — Bluetooth/firmware loader first, then Wi-Fi:

```bash
sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv
```

Or with `insmod` (if not installed):

```bash
sudo insmod drivers/aic8800/aic_load_fw/aic_load_fw.ko
sudo insmod drivers/aic8800/aic8800_fdrv/aic8800_fdrv.ko
```

Verify:

```bash
lsmod | grep aic
```

## Unloading the Driver

```bash
sudo modprobe -r aic8800_fdrv
sudo modprobe -r aic_load_fw
```

Or with `rmmod`:

```bash
sudo rmmod aic8800_fdrv
sudo rmmod aic_load_fw
```

## Uninstallation

### Automatic

```bash
sudo make uninstall
```

### Manual

```bash
sudo rmmod aic8800_fdrv
sudo rmmod aic_load_fw
sudo rm -rf /lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800
sudo rm -rf /lib/firmware/aic8800D80
sudo rm /etc/udev/rules.d/aic.rules
sudo udevadm control --reload-rules
sudo depmod -a $(uname -r)
```

## Usage

Once loaded, the wireless interface appears automatically:

```bash
ip link
iwconfig
```

Manage with standard tools: `nmcli`, `nmtui`, `wpa_supplicant`, etc.

## Troubleshooting

### Driver fails to load

Check kernel messages for errors:

```bash
dmesg | tail -50
```

### Firmware not found

Ensure firmware files exist:

```bash
ls /lib/firmware/aic8800D80/
```

Expected files:

- `fmacfw_8800d80_u02.bin`
- `fw_patch_8800d80_u02.bin`
- `fw_patch_table_8800d80_u02.bin`
- `fw_adid_8800d80_u02.bin`
- `lmacfw_rf_8800d80_u02.bin`
- `calibmode_8800d80.bin`
- `fw_ble_scan_ad_filter.bin`
- `aic_userconfig_8800d80.txt`

### Module version mismatch

If you see `module verification failed` or version errors, rebuild after kernel update:

```bash
make clean && make
sudo make install
```

### Interface not appearing after load

```bash
# Check if modules are loaded
lsmod | grep aic

# Check for errors
dmesg | grep -i aic

# Restart network manager
sudo systemctl restart NetworkManager
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
