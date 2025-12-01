# Debian Indestructible 🛡️

> *Because your system should survive anything—even your own mistakes.*

## Overview

**Debian Indestructible** is a comprehensive guide for building a resilient, snapshot-capable Debian vanilla system using BTRFS and Snapper. This setup combines Debian's rock solid stability with the advanced features of BTRFS snapshots, allowing you to roll back system changes effortlessly and recover from catastrophic failures.

Whether you're experimenting with new software, performing risky upgrades, or simply want peace of mind, this guide will help you create a system that's virtually indestructible.

## What Makes It "Indestructible"?

- **Atomic Snapshots**: Take instant snapshots of your entire system before any major change
- **Effortless Rollbacks**: Boot directly into previous snapshots from GRUB if something breaks
- **Fine-Grained Control**: Exclude specific directories (like `/home`, `/var/lib/docker`, etc) from snapshots
- **Automatic Snapshots**: Timeline-based snapshots capture your system state throughout the day
- **Full Disk Encryption**: Optional LUKS2 encryption with modern argon2id (GRUB 2.14rc and up) or pbkdf2 key derivation
- **Hibernation Support**: Properly configured hibernation with swapfile or swap partition
- **Desktop Environment Ready**: Includes configurations for GNOME, KDE, XFCE, and display managers

## Installation variants

This repository provides six installation variants:

### Standard EFI Systems (x86_64)
- **EFI + ZRAM**: Compressed RAM-based swap (no hibernation)
- **EFI + Swap Partition**: Traditional swap partition for hibernation
- **EFI + Swapfile**: Basic setup with hibernation support via swapfile

### Encrypted EFI Systems (x86_64)
- **EFI + LUKS2 + ZRAM**: Encrypted system with ZRAM (no hibernation)
- **EFI + LUKS2 + Swap Partition**: Encrypted system with separate encrypted swap
- **EFI + LUKS2 + Swapfile**: Full disk encryption with hibernation

All configurations use:
- BTRFS with Snapper for snapshot management
- Optimized subvolume layout inspired by openSUSE
- GRUB bootloader with grub-btrfs integration
- Debootstrap for minimal, controlled installations

## Prerequisites

### Recommended Live Environment

For the best experience, use a Debian or Ubuntu-based live environment:

- **[Kubuntu](https://kubuntu.org/download/)** - Ubuntu with KDE Plasma
- **[Debian Live with KDE](https://www.debian.org/CD/live/)** - Official Debian live image
- **[Ubuntu](https://ubuntu.com/download/desktop)** - Standard Ubuntu with GNOME

These live environments include necessary tools and provide a comfortable desktop experience during installation.

### Minimum Requirements

- 64-bit x86_64 processor
- 4 GB RAM minimum (8 GB+ recommended)
- 70 GB disk space (more for `/home`, application data and snapshots)
- UEFI firmware (for EFI installations)
- Internet connection during installation

## Installation Guides

### Standard EFI Systems x86_64

| Guide | Swap Type | Hibernation |
|-------|-----------|-------------|
| [EFI + ZRAM](guides/EFI-ZRAM.md) | Compressed RAM | ❌ No | 
| [EFI + Swap Partition](guides/EFI-SWAPPARTITION.md) | Dedicated partition | ✅ Yes 
| [EFI + Swapfile](guides/EFI-SWAPFILE.md) | BTRFS swapfile | ✅ Yes | 

### Encrypted EFI Systems x86_64 (Coming Soon 🚧, waiting until [GRUB 2.14rc](https://packages.debian.org/sid/grub-efi-amd64-signed) arrives in Debian Sid)

| Guide | Encryption | Swap Type | Hibernation |
|-------|------------|-----------|-------------|
| [EFI + LUKS2 + ZRAM](guides/EFI-LUKS2-ZRAM.md) | LUKS2 | Compressed RAM | ❌ No | 
| [EFI + LUKS2 + Swap Partition](guides/EFI-LUKS2-SWAPPARTITION.md) | LUKS2 | Encrypted partition | ✅ Yes | 
| [EFI + LUKS2 + Swapfile](guides/EFI-LUKS2-SWAPFILE.md) | LUKS2 | BTRFS swapfile | ✅ Yes | 

### Standard BIOS-MBR Systems

> 🚧 **Coming Soon**: BIOS-MBR installation guides are currently in development. These will support legacy BIOS systems with the same snapshot and rollback capabilities.

### Encrypted BIOS-MBR Systems

> 🚧 **Coming Soon**: Encrypted BIOS-MBR installation guides are also planned, providing full disk encryption alongside snapshot features for legacy systems.

## Key Features Explained

### BTRFS Subvolume Layout

The installation creates a carefully designed subvolume structure that:

- Keeps package manager databases consistent across snapshots
- Excludes user data, logs, and caches from automatic snapshots
- Prevents data loss when rolling back system changes
- Optimizes disk space usage

### Snapper Integration

Automatic snapshot management with:

- Pre/post snapshots around package operations
- Hourly, daily, weekly, and monthly timeline snapshots
- Configurable retention policies
- Bootable snapshots accessible from GRUB

### GRUB Rollback Plugin

A custom Snapper plugin that:

- Detects snapshot rollback requests
- Automatically updates GRUB configuration
- Ensures kernel and initramfs match the restored snapshot path
- Logs operations for troubleshooting

This [plugin](https://github.com/JMarcosHP/Debian-Indestructible/blob/main/snapper-plugins/99-rollback-grub) bridges the gap between Debian/Ubuntu and openSUSE's native snapshot integration, making rollbacks truly seamless.
For a detailed explanation about this plugin please [see](plugin-explanation.md).

## Post-Installation

After completing your installation, you can enhance your system using the provided installation script:

```bash
cd ~/Debian-Indestructible
chmod +x install-debian.sh
./install-debian.sh <parameter>
```
You can check the package list [here](install-debian.sh).

**Available options:**
- `base`                                            - Essential system packages
- `utilities`                                       - Additional useful tools
- `basic-server`                                    - Basic Server packages (SSH, etc.)
- `gnome-desktop` / `kde-desktop` / `xfce4-desktop` - Full desktop environments
- `gnome-extensions`                                - Gnome Extensions provided by Debian
- `gnome-flatpak` / `kde-flatpak` / `xfce4-flatpak` - Flatpak integration
- `gnome-snapd`   / `kde-snapd`   / `xfce4-snapd`   - Snapd integration
- `fcitx5-support-gnome` / `fcitx5-support-kde`     - Input method support
- `restricted-extras`                               - Codecs and proprietary software
- `gaming`                                          - Gaming essentials

**Recommended installation order for Desktop:**
```bash
./install-debian.sh base
./install-debian.sh utilities
./install-debian.sh kde-desktop
./install-debian.sh kde-flatpak
./install-debian.sh fcitx5-support-kde # Optional
./install-debian.sh restricted-extras
./install-debian.sh gaming
```

**Recommended installation order for Server:**

```bash
./install-debian.sh base
./install-debian.sh utilities
./install-debian.sh basic-server
```

## Rolling Back Your System

Learn how to perform system rollbacks and manage snapshots in the [Rollback Guide](rollbacks.md).

## Contributing

Contributions are welcome! If you find issues, have suggestions, or want to add support for new configurations, please open an issue or submit a pull request.

## Support the Project

If this guide helped you to build a more resilient system, consider supporting further development:

**Available Methods:**
- [PayPal](https://paypal.me/JMarcosHP)
- [Github Sponsors](https://github.com/sponsors/JMarcosHP)

Testing and research takes a lot of time, every contribution helps maintain and improve these guides. Thank you! 💙

## License

This project is licensed under the GNU GPL v3.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Special thanks to:

- The [openSUSE](https://www.opensuse.org/) team for pioneering BTRFS snapshot integration
- [Siduction developers](https://github.com/siduction) for the GRUB rollback implementation
- [GRUB-BTRFS developers](https://github.com/Antynea/grub-btrfs) for snapshots menu integration
- The Debian and Linux communities for extensive documentation

## Resources that complemented every guide in this repository

- [BTRFS Documentation](https://btrfs.readthedocs.io/)
- [Snapper Documentation](http://snapper.io/)
- [Arch Wiki - Snapper](https://wiki.archlinux.org/title/Snapper)
- [openSUSE BTRFS layout](https://en.opensuse.org/SDB:BTRFS)
- [rootco.de - openSUSE BTRFS Subvolumes](https://rootco.de/2018-01-19-opensuse-btrfs-subvolumes/)
- [Moslehian - Reliable BTRFS Snapshots with Snapper on Debian/Ubuntu](https://moslehian.com/posts/2023/2-reliable-btrfs-snapshots-snapper-debian-ubuntu/)
- [Zlendy - Install Arch Linux with BTRFS and Snapper](https://zlendy.com/blog/install-arch-linux-with-btrfs-and-snapper)
- [Arch Wiki - Snapper Filesystem Layout](https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout)
- [Kali Linux - BTRFS Installation](https://www.kali.org/docs/installation/btrfs/)
- [SysGuides - Install Debian 13 with BTRFS](https://sysguides.com/install-debian-13-with-btrfs)
- [DevelMonk - Debootstrap to Thin LVM](https://develmonk.com/2024/08/12/the-miracle-of-debootstrap-installing-ubuntu-to-thin-lvm-in-a-very-archlinux-like-way/)
- [Th3Whit3Wolf - Archlinux BTRFS installation script](https://gist.github.com/Th3Whit3Wolf/0150bd13f4b2667437c55b71bfb073e4)
- [Dawaltconley - Enabling hibernation with FDE Pop!_OS](https://gist.github.com/dawaltconley/8cb4c3cfac7da394a58fab363628bf63)
- [Mutschler - Ubuntu 20.04 BTRFS Setup](https://mutschler.dev/linux/ubuntu-btrfs-20-04/)
- [Stefan Proell - Full Disk Encryption and Hibernation](https://www.stefanproell.at/posts/2022-11-01-fde-hibernate/)
- [SpiralLinux - BTRFS Discussion](https://github.com/orgs/SpiralLinux/discussions/497)
- [Leo3418 - LUKS2 GRUB Systemd Configuration](https://leo3418.github.io/collections/gentoo-config-luks2-grub-systemd/tune-parameters.html)
- [openSUSE - Lowering GRUB decryption time](https://en.opensuse.org/SDB:Encrypted_root_file_system#GRUB_level_decryption_at_boot_is_too_slow)
- [Arch Wiki - ZRAM Swap Optimization](https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram)
- [Snapper GRUB configuration Issue](https://github.com/openSUSE/snapper/issues/722)
- [Siduction BTRFS Rollback Script](https://github.com/siduction/siduction-btrfs/blob/main/siduction-btrfs-0.4.0/rollback-grub.sh)
- [RFC 9106 - Argon2 Password Hashing](https://datatracker.ietf.org/doc/html/rfc9106)
- [openSUSE Rollback guide](https://es.opensuse.org/Snapper_Rollback)

---

**Made with ❤️ for the Debian community**
