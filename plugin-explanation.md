# Snapper GRUB Rollback Plugin

## Overview

The Snapper [GRUB Rollback Plugin](https://github.com/JMarcosHP/Debian-Indestructible/blob/main/snapper-plugins/99-rollback-grub) is a critical component that bridges the gap between snapshot creation and bootable system recovery. Unlike openSUSE, which has native integration between Snapper and the bootloader, Debian and Ubuntu require additional configuration to ensure snapshots are properly bootable.

## The Problem

When you perform a Snapper rollback in standard Debian/Ubuntu installations, the system updates which snapshot is used as the default subvolume. However, **GRUB continues to read the kernel and initramfs from the old snapshot location**. This mismatch can cause:

- Boot failures due to mismatched kernel versions
- Inability to load necessary kernel modules
- Confusion about which snapshot is actually running

This issue is documented in [openSUSE Snapper Issue #722](https://github.com/openSUSE/snapper/issues/722).

## The Solution

This custom Snapper plugin automatically handles GRUB reconfiguration during rollbacks, ensuring the bootloader configuration stays synchronized with the active snapshot.

## How It Works

The plugin executes automatically when Snapper performs a rollback operation:

### 1. Rollback Detection
The plugin detects when a user initiates a rollback of the root (`/`) configuration:
```bash
snapper -c root rollback <snapshot-number>
```

### 2. Snapshot Information Gathering
It identifies:
- The number of the new writable snapshot that Snapper creates
- The full path of the new default BTRFS subvolume
- Whether the system uses EFI or BIOS-MBR boot mode

### 3. Boot Mode Detection
The plugin determines the boot configuration:
- **EFI mode**: Checks for `/sys/firmware/efi`
- **BIOS-MBR mode**: Validates MBR disk configuration

### 4. Temporary Mount and Chroot
Creates a temporary directory and:
- Mounts the new default snapshot subvolume
- Bind-mounts necessary filesystems (`/dev`, `/proc`, `/sys`, `/run`)
- Performs a `chroot` into the new snapshot environment

### 5. GRUB Reinstallation
Inside the chroot:
- Reinstalls GRUB to ensure the bootloader points to correct locations
- Updates `grub.cfg` with proper kernel and initramfs paths
- Ensures all boot parameters are correctly configured

### 6. Cleanup and Logging
- Unmounts all temporary mounts
- Logs all operations to `/var/log/snapper.log` for troubleshooting
- Exits with appropriate status codes

## Installation

The plugin is installed during the main system setup:

```bash
# Create plugin directory inside chroot
mkdir -p /usr/lib/snapper/plugins

# Copy the plugin (from outside chroot)
exit
cp -r ~/Debian-Indestructible/snapper-plugins/99-rollback-grub \
    /mnt/usr/lib/snapper/plugins

# Make executable
chmod +x /mnt/usr/lib/snapper/plugins/99-rollback-grub
```

## Compatibility

The plugin is designed for:

**Compatible with:**
- Debian (all versions)
- Ubuntu and derivatives
- Any distribution using standard `grub-install` and `grub-mkconfig` commands
- Systems following this guide's BTRFS subvolume layout

**Requirements:**
- GRUB as the bootloader
- Snapper with the root configuration named `root`
- BTRFS filesystem with snapshot-capable subvolumes
- Standard Linux directory structure

## Troubleshooting

### Check Plugin Execution

View the Snapper log after a rollback:
```bash
sudo tail -f /var/log/snapper.log
```

### Verify Snapshot Mount

Check if the default subvolume changed:
```bash
sudo btrfs subvolume get-default /
```

Check if the EFI partition is pointing to the correct path:
```bash
sudo cat /boot/efi/EFI/debian/grub.cfg
```

The output should show the correct snapshot subvolume path.

## Technical Details

### Plugin Location
```
/usr/lib/snapper/plugins/99-rollback-grub
```

The `99-` prefix ensures this plugin runs last, after Snapper completes its rollback operations.

### Execution Environment

The plugin runs with:
- Root privileges
- Access to Snapper's rollback context
- Full system access for mounting and chroot operations

## Credits

This implementation is based on [Siduction's rollback-grub.sh](https://github.com/siduction/siduction-btrfs/blob/main/siduction-btrfs-0.4.0/rollback-grub.sh), adapted for Debian/Ubuntu systems with enhancements for error handling and logging.

Special thanks to the Siduction developers for sharing this solution.

## See Also

- [Installation variants](https://github.com/JMarcosHP/Debian-Indestructible#installation-variants)
- [Rollback Guide](https://github.com/JMarcosHP/Debian-Indestructible/blob/main/rollbacks.md)
- [openSUSE Snapper Issue #722](https://github.com/openSUSE/snapper/issues/722)
- [Siduction BTRFS Implementation](https://github.com/siduction/siduction-btrfs)