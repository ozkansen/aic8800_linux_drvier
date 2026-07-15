# AIC8800 Linux Driver

Linux driver for the AIC8800 Wi-Fi/BT chipset, supporting USB and SDIO interfaces.

## How It Works

The AIC8800 chipset boots in **USB Mass Storage mode** (vendor `a69c`, product `5721`), appearing as a flash drive. This is normal — the flash drive contains the chip's firmware. To switch to WiFi mode, the mass storage device must be **ejected**. After eject, the chip re-enumerates as a WiFi device and the driver takes over.

```
Boot → USB Mass Storage (a69c:5721) → Eject → Re-enumerate as WiFi → Driver loads firmware → wlan0 appears
```

The WiFi mode product ID varies by board variant:

| Vendor | Product | Chip | Notes |
|--------|---------|------|-------|
| `a69c` | `8800` | AIC8800 | Standard |
| `a69c` | `8801` | AIC8801 | |
| `a69c` | `88dc` | AIC8800DC | Standard DC |
| `2c4e` | `0126` | AIC8800DC | Mercucys variant (Orange Pi) |

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

Load modules. The required modules depend on your chip variant:

### AIC8800DC (most common, e.g. Orange Pi, Mercucys)

Only the WiFi driver is needed — firmware is loaded automatically:

```bash
sudo modprobe aic8800_fdrv
```

### AIC8800 / AIC8800D80

Load firmware loader first, then WiFi driver:

```bash
sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv
```

To check which chip you have:

```bash
lsusb | grep -i aic
# a69c:8800 or 2c4e:0126 → AIC8800DC (WiFi driver only)
# a69c:8d80             → AIC8800D80 (both modules)
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
sudo rm -rf /lib/firmware/aic8800DC
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
alias:          usb:v2C4Ep0126d*
```

If you see `sdio:` aliases instead, the SDIO version is installed. Rebuild and reinstall:

```bash
make clean && make
sudo make uninstall
sudo make install
```

## Verifying WiFi Device Detection

After eject, check `lsusb` for the WiFi device:

```bash
lsusb | grep -i aic
```

Expected (one of):

```
Bus XXX Device YYY: ID a69c:8800 aicsemi AIC8800     # Standard
Bus XXX Device YYY: ID 2c4e:0126 Mercucys INC AIC8800DC  # Mercucys variant
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

Verify firmware exists for your chip variant:

```bash
# AIC8800DC
ls -la /lib/firmware/aic8800DC/

# AIC8800D80
ls -la /lib/firmware/aic8800D80/
```

If firmware is missing, re-run `sudo make install`.

### "fmacfw_patch_8800dc_u02.bin failed to open"

Your device is AIC8800DC and needs DC firmware. The firmware is included in this repo under `fw/aic8800DC/`. Run `sudo make install` to copy it to `/lib/firmware/aic8800DC/`.
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
