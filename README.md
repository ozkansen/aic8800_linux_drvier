# AIC8800 Linux Driver

Linux driver for the AIC8800 Wi-Fi/BT chipset, supporting USB and SDIO interfaces.

## How It Works

The AIC8800 chipset boots in **USB Mass Storage mode** (product ID `0x5721`), appearing as a flash drive. This is normal — the flash drive contains the chip's firmware. To switch to WiFi mode, the mass storage device must be **ejected**. After eject, the chip re-enumerates as a WiFi device and the driver takes over.

```
Boot → USB Mass Storage (0x5721) → Eject → Re-enumerate as WiFi (0x8800) → Driver loads firmware → wlan0 appears
```

The `install_setup.sh` script handles the eject automatically. The udev rule in `tools/aic.rules` also auto-ejects on boot.

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

### Automatic (Recommended)

```bash
sudo make install
```

This will:

1. Build the driver modules
2. Install modules to `/lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800/`
3. Copy firmware files to `/lib/firmware/aic8800D80/`
4. Install udev rules to `/etc/udev/rules.d/aic.rules`
5. Reload udev and auto-eject USB mass storage
6. Print next-step instructions

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

Load modules in order — firmware loader first, then Wi-Fi:

```bash
sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv
```

Or with `insmod` (if not installed via `make install`):

```bash
sudo insmod drivers/aic8800/aic_load_fw/aic_load_fw.ko
sudo insmod drivers/aic8800/aic8800_fdrv/aic8800_fdrv.ko
```

Verify modules are loaded:

```bash
lsmod | grep aic
```

## Unloading the Driver

```bash
sudo modprobe -r aic8800_fdrv
sudo modprobe -r aic_load_fw
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

## Verifying Correct Module Installation

After installation, verify the WiFi driver is the **USB version**, not SDIO:

```bash
modinfo aic8800_fdrv | grep alias
```

Expected output (USB):

```
alias:          usb:vA69Cp8800d*
alias:          usb:vA69Cp8801d*
alias:          usb:vA69Cp8D81d*
```

If you see `sdio:` aliases instead, the SDIO version is installed. Rebuild and reinstall:

```bash
make clean && make
sudo make uninstall
sudo make install
```

## Troubleshooting

### Device stuck in USB Mass Storage mode

If `lsusb` shows `a69c:5721 aicsemi Aic MSC` after running `make install`:

```bash
# Manual eject
sudo eject /dev/aicudisk    # if symlink exists
# or find the SCSI disk
lsblk -d -o NAME,MODEL | grep -i AIC
sudo eject /dev/sdX         # replace sdX with the actual disk
```

### wlan0 does not appear after loading modules

Check for errors:

```bash
dmesg | tail -30
dmesg | grep -i aic
```

Verify firmware exists:

```bash
ls -la /lib/firmware/aic8800D80/
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

### modprobe fails with "Exec format error"

This usually means the module was compiled for a different kernel. Rebuild:

```bash
make clean && make
sudo make uninstall
sudo make install
sudo depmod -a $(uname -r)
```

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
