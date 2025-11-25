# Debian Indestructible: Standard EFI System with ZRAM

> *Maximum performance, minimal disk usage—swap reimagined.*

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Disk Partitioning Scheme](#disk-partitioning-scheme)
- [Installation Steps](#installation-steps)
  - [Initial Setup](#initial-setup)
  - [Disk Preparation](#disk-preparation)
  - [BTRFS Configuration](#btrfs-configuration)
  - [Subvolume Creation](#subvolume-creation)
  - [System Deployment](#system-deployment)
  - [System Configuration](#system-configuration)
  - [ZRAM Configuration](#zram-configuration)
  - [Bootloader Installation](#bootloader-installation)
  - [Snapper Setup](#snapper-setup)
- [Post-Installation](#post-installation)
- [Conclusion](#conclusion)

## Introduction

This guide sets up Debian with ZRAM, a compressed block device in RAM that serves as ultra-fast swap space. Unlike traditional swap files or partitions, ZRAM:

- **Operates entirely in RAM**: No disk I/O bottlenecks
- **Uses compression**: Typically achieves 2-3x compression ratios with ZSTD
- **Extends effective RAM**: 8 GB physical RAM can behave like 12-16 GB
- **Reduces disk wear**: Perfect for SSDs and eMMC storage
- **Improves responsiveness**: Instant swap operations

**Trade-off**: Hibernation (suspend-to-disk) is not available with this setup, as there's no persistent swap storage.

This configuration is ideal for:
- Systems with limited RAM (2-4 GB)
- Users who never use hibernation
- SSD/NVMe systems where disk wear matters
- Performance enthusiasts
- Systems with fast multi-core processors (better compression performance)

## Prerequisites

- **Live Environment**: Debian or Ubuntu-based live system ([recommended options](https://github.com/JMarcosHP/Debian-Indestructible#recommended-live-environment))
- **System Type**: UEFI firmware (check with `ls /sys/firmware/efi`)
- **Disk Space**: Minimum 70 GB (more recommended for home and data)
- **RAM**: 4 GB minimum, 8 GB+ recommended for optimal multitasking
- **Internet Connection**: Required during installation
- **Backup**: All data on the target disk will be erased

## Disk Partitioning Scheme

| Partition | Device | Label | Type | Format | Size | Mount Point |
|-----------|---------|-------|------|--------|------|-------------|
| **EFI System Partition** | `/dev/device1` | `ESP` | EFI System | FAT32 | 512 MiB | `/boot/efi` |
| **System Partition** | `/dev/device2` | `SYSTEM` | Linux Filesystem | BTRFS | 70 GiB+ | `/` |
| **ZRAM Device** | `/dev/zram0` | - | Compressed RAM | - | 100% RAM | In-memory swap |

**Notes:**
- Replace `/dev/device1` and `/dev/device2` with your actual device paths (e.g., `/dev/sda1`, `/dev/nvme0n1p1`)
- ZRAM is configured to use 100% of available RAM with ZSTD compression
- No physical swap partition or swapfile needed
- Hibernation is **not available** with this configuration

## Installation Steps

### Initial Setup

Boot into your live environment and open a terminal.

#### 1. Gain Root Access

```bash
sudo su -
cd ~/
```

#### 2. Update Package Lists

```bash
apt update
```

#### 3. Install Required Tools

```bash
apt install -y debootstrap arch-install-scripts git
```

#### 4. Clone the Debian Indestructible Repository

```bash
git clone https://github.com/JMarcosHP/Debian-Indestructible.git
```

This repository contains helper scripts and configuration files we'll use throughout the installation.

### Disk Preparation

#### 5. Identify Your Target Disk

```bash
fdisk -l
```

Carefully note your target disk (e.g., `/dev/sda`, `/dev/nvme0n1`). **All data on this disk will be permanently erased.**

#### 6. Create Partition Table

```bash
cfdisk /dev/device  # Replace 'device' with your disk name
```

In cfdisk:
1. Select **gpt** partition table type
2. Create the **EFI System Partition**:
   - Size: `512MiB`
   - Type: `EFI System`
3. Create the **System Partition**:
   - Size: Remaining space (or desired size)
   - Type: `Linux filesystem`
4. Write changes and exit

Take note of the partition numbers created (e.g., `/dev/sda1`, `/dev/sda2`).

#### 7. Format Partitions

```bash
mkfs.vfat -F32 -n ESP /dev/device1
mkfs.btrfs -L SYSTEM /dev/device2
```

Replace `/dev/device1` and `/dev/device2` with your actual partition paths.

### BTRFS Configuration

#### 8. Define BTRFS Mount Options

```bash
BTRFS_OPTS="noatime,nodiratime,compress-force=zstd:3,space_cache=v2,commit=120"
```

**Options explained:**
- `noatime,nodiratime` - Don't update access times (improves performance)
- `compress-force=zstd:3` - Force ZSTD compression, level 3 (balanced)
- `space_cache=v2` - Use improved free space cache
- `commit=120` - Commit interval of 120 seconds (reduces SSD writes)

#### 9. Define System Variables

```bash
ESP="$(blkid -L ESP)"
ESP_UUID="$(blkid -t LABEL=ESP -o value -s UUID)"
SYSTEM="$(blkid -L SYSTEM)"
SYSTEM_UUID="$(blkid -t LABEL=SYSTEM -o value -s UUID)"
```

**Important**: Keep this terminal open throughout the installation to preserve these variables.

#### 10. Mount the BTRFS Partition

```bash
mount -vo $BTRFS_OPTS $SYSTEM /mnt
cd /mnt
```

### Subvolume Creation

#### Understanding the BTRFS Layout

The system uses a carefully designed subvolume structure:

- `@` - The main subvolume containing all the child system subvolumes.
- `@/.snapshots` - Stores all Snapper snapshots
- `@/.snapshots/1/snapshot` - **First default subvolume** this will be used to mount all the other subvolumes and works like the real filesystem
- `@/root` - The Root user's home directory
- `@/home` - User home directory (configurable snapshots)
- `@/opt` - Excluded to avoid uninstalling third party software on rollbacks
- `@/srv` - Contains data for many server rolls. Excluded to avoid data loss on rollbacks
- `@/usr/local` - Locally compiled software. Excluded to avoid data loss on rollbacks.
- `@/var/lib/machines` - Used by Systemd machinectl
- `@/var/lib/portables` - Used by Systemd portablectl
- `@/var/log` - System logs (Must be writable in read-only snapshots to allow booting without issues)
- `@/var/cache` - This excludes cache data during snapshots.
- `@/var/spool` - Excluded to avoid data loss of cron jobs, mails, news and print queues.
- `@/var/tmp` - This excludes temporary files during snapshots.
- `@/tmp` - This excludes temporary files during snapshots.

**Why this layout?**

The `/var/lib/dpkg` and `/var/lib/apt` directories must remain in the default subvolume to ensure package manager consistency across snapshots. This is a Debian/Ubuntu requirement, unlike openSUSE which can use a single `/var` subvolume.

**Specific subvolumes for Desktop Environments**

Some desktop environments must have specific directories as writable in order to boot without issues in Snapper's read-only snapshots.

For any Desktop Environment:

`/var/lib/AccountsService`

Needs to be writable for the `accountsservice` package, this package provides D-Bus interfaces for managing user account information and uses the `/var/lib/AccountsService` directory to store user-related settings, such as user pictures and default sessions.

Gnome:

`/var/lib/gdm3`

Needs to be writable for GDM configurations

KDE:

`/var/lib/sddm`

Needs to be writable for SDDM configurations

Lightdm based Desktop Environment:

`/var/lib/lightdm`

Needs to be writable for LightDM configurations

**Specific subvolumes for applications/software:**

If you want to use docker, virtual machines, lxc containers, databases or waydroid,
consider creating subvolumes for other directories that contain data you do not want to include in snapshots and rollbacks to avoid running out of space, examples are:

Docker:
```bash
/var/lib/docker
/var/lib/containerd
```

All related container images and volumes are stored there.

Podman:

`/var/lib/containers`

All related container images and volumes are stored there.

QEMU/Libvirt virtual machines and LXC containers:

`/var/lib/libvirt`
These two applies to waydroid too
```bash
/var/lib/lxc
/var/lib/lxcfs
```

Virtual machine disks and many other configurations are stored there.

Databases:
```bash
/var/lib/postgresql
/var/lib/mysql
/var/lib/mongodb
```

The database related data and files are stored there.

Waydroid:

`/var/lib/waydroid`

Waydroid Android images and related configurations are stored there.

Flatpak:

`/var/lib/flatpak`

All system-wide flatpak applications are stored there.

Snap:
```bash
/var/lib/snapd
/var/snap
/snap
```

Snapd related configuration are stored there.

#### 11. Create Main Subvolume

```bash
btrfs su cre /mnt/@
mkdir -vp /mnt/@/{usr,var/lib}
```

#### 12. Define Subvolumes to Create

Edit this array according to your needs. Uncomment lines for desktop environments, containers, databases, etc.

```bash
SUBVOLUMES=(
    # Basic system subvolumes
    "@/root"
    "@/home"
    "@/opt"
    "@/srv"
    "@/usr/local"
    "@/var/log"
    "@/var/cache"
    "@/var/spool"
    "@/var/tmp"
    "@/var/lib/machines"
    "@/var/lib/portables"
    "@/.snapshots"
    "@/tmp"

    # REQUIRED for any desktop environment
    #"@/var/lib/AccountsService"

    # GNOME GDM Specific
    #"@/var/lib/gdm3"

    # KDE SDDM Specific
    #"@/var/lib/sddm"

    # LightDM based desktop environments
    #"@/var/lib/lightdm"

    # Flatpak
    #"@/var/lib/flatpak"

    # Snap
    #"@/var/lib/snapd"
    #"@/var/snap"
    #"@/snap"

    # Virtual Machines & Containers
    #"@/var/lib/libvirt"
    #"@/var/lib/lxc"
    #"@/var/lib/lxcfs"

    # Docker
    #"@/var/lib/docker"
    #"@/var/lib/containerd"

    # Podman
    #"@/var/lib/containers"

    # Waydroid
    #"@/var/lib/waydroid"

    # Databases
    #"@/var/lib/postgresql"
    #"@/var/lib/mysql"
    #"@/var/lib/mongodb"

    # Extra
    # ...
)
```

**Tip**: For desktop environments, always uncomment `@/var/lib/AccountsService` and the specific display manager subvolume.

#### 13. Create All Subvolumes

```bash
for SUBVOLUME in "${SUBVOLUMES[@]}"
do
    btrfs su cre /mnt/$SUBVOLUME
done
```

#### 14. Create Default Snapshot

```bash
mkdir /mnt/@/.snapshots/1
btrfs su cre /mnt/@/.snapshots/1/snapshot
```

#### 15. Configure Snapper Metadata

```bash
bash -c "cat > /mnt/@/.snapshots/1/info.xml" <<EOF
<?xml version="1.0"?>
<snapshot>
  <type>single</type>
  <num>1</num>
  <date>$(date -u +"%F %T")</date>
  <description>first root filesystem</description>
</snapshot>
EOF
```

#### 16. Set Default Subvolume

```bash
btrfs subvolume set-default $(btrfs subvolume list /mnt | grep "@/.snapshots/1/snapshot" | grep -oP '(?<=ID )[0-9]+') /mnt
```

#### 17. Remount with Default Subvolume

```bash
cd /
umount /mnt
mount -vo $BTRFS_OPTS $SYSTEM /mnt
cd /mnt
```

### Filesystem Skeleton

#### 18. Define Directory Structure

Adjust this array to match your subvolume configuration:

```bash
DIRECTORIES=(
    # Basic system directories
    "boot/efi"
    "root"
    "home"
    "opt"
    "srv"
    "usr/local"
    "media/cdrom"
    "var/log"
    "var/cache"
    "var/spool"
    "var/tmp"
    "var/lib/machines"
    "var/lib/portables"
    ".snapshots"
    "tmp"

    # REQUIRED for any desktop environment
    #"var/lib/AccountsService"

    # GNOME GDM Specific
    #"var/lib/gdm3"

    # KDE SDDM Specific
    #"var/lib/sddm"

    # LightDM based desktop environment
    #"var/lib/lightdm"

    # Flatpak
    #"var/lib/flatpak"

    # Snap
    #"var/lib/snapd"
    #"var/snap"
    #"snap"

    # Virtual Machines & LXCs
    #"var/lib/libvirt"
    #"var/lib/lxc"
    #"var/lib/lxcfs"

    # Docker
    #"var/lib/docker"
    #"var/lib/containerd"

    # Podman
    #"var/lib/containers"

    # Waydroid
    #"var/lib/waydroid"

    # Databases
    #"var/lib/postgres"
    #"var/lib/mysql"
    #"var/lib/mongodb"

    # Extra
    # ...
)
```

#### 19. Create Directories

```bash
for DIRECTORY in "${DIRECTORIES[@]}"
do
    mkdir -vp /mnt/$DIRECTORY
done
```

### Mounting

#### 20. Mount EFI Partition

```bash
mount -vo noatime,nodiratime,errors=remount-ro $ESP /mnt/boot/efi
```

#### 21. Mount All Subvolumes

```bash
MOUNTPOINTS=()
for SUBVOLUME in "${SUBVOLUMES[@]}"
do
    MOUNTPOINTS+=("${SUBVOLUME#@/}")
done

for i in "${!SUBVOLUMES[@]}"
do
    mount -vo $BTRFS_OPTS,subvol=${SUBVOLUMES[$i]} $SYSTEM /mnt/${MOUNTPOINTS[$i]}
done
```

#### 22. Disable COW for Variable Data

```bash
chattr +C -R /mnt/var
chattr +C -R /mnt/snap  # Optional: if using Snap packages
```

### System Deployment

#### 23. Bootstrap Debian Base System

Choose your Debian release: `sid`, `testing`, `forky`, `trixie`, `stable`, etc.

```bash
debootstrap --arch=amd64 \
--components=main,contrib,non-free,non-free-firmware \
--include=locales,tzdata,keyboard-configuration,console-setup,console-data,sudo,task-english,manpages,man-db,vim,bash-completion,btrfs-progs,snapper,build-essential,git,net-tools,acl,inotify-tools,btrfsmaintenance,aptitude,xfsprogs,htop,ca-certificates,zstd,plocate \
sid /mnt http://deb.debian.org/debian
```

**Customize**:
- Replace `task-english` with your language task package (e.g., `task-german`)
- Add `task-laptop` if installing on a laptop
- Replace `sid` with your chosen Debian release.

#### 24. Bind-Mount System Directories

```bash
for dir in dev proc sys run; do
    mount -v --rbind "/${dir}" "/mnt/${dir}"
    mount -v --make-rslave "/mnt/${dir}"
done
```

### FSTAB Configuration

#### 25. Generate fstab

**Option A: Generate automatically and adjust to your needs**
```bash
genfstab -U /mnt > /mnt/etc/fstab
nano /mnt/etc/fstab
```

**Option B: Use provided template**
```bash
cp -r ~/Debian-Indestructible/configuration/fstab /mnt/etc/
sed -i "s/dummy-esp/$ESP_UUID/g; s/dummy-system/$SYSTEM_UUID/g" /mnt/etc/fstab
```

#### 26. Verify and Edit fstab

```bash
nano /mnt/etc/fstab
```
For option A ensure:
- ESP is mounted at `/boot/efi`
- All your subvolumes are correctly listed
- **No swap entries**
- Mount options are correct

For option B:

Edit the file and uncomment your selected subvolumes, except the swap entries.

#### 27. Copy System Configuration Files

```bash
cp -r ~/Debian-Indestructible/configuration/99-custom.conf /mnt/etc/sysctl.d/
```

This file contains kernel parameter optimizations for ZRAM and networking performance.

### System Configuration

#### 28. Enter Chroot Environment

```bash
chroot /mnt /bin/bash
```

You're now inside your new system!

#### 29. Set Hostname

```bash
echo "yourhostname" > /etc/hostname
```

Replace `yourhostname` with your desired computer name.

#### 30. Configure Hosts File

```bash
cat > /etc/hosts << EOF
127.0.0.1       localhost
127.0.1.1       $(cat /etc/hostname)

::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF
```

#### 31. Configure Localization

```bash
dpkg-reconfigure locales tzdata keyboard-configuration console-setup
```

Follow the interactive prompts to set:
- System locale
- Timezone
- Keyboard layout
- Console font

#### 32. Configure APT Sources

```bash
mv /etc/apt/sources.list /etc/apt/sources.list.bak

cat > /etc/apt/sources.list.d/debian.sources << EOF
Types: deb deb-src
URIs: http://deb.debian.org/debian/
Suites: sid experimental
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
```

Add the full sources for your specific Debian release, you can copy an example from (here)[https://github.com/JMarcosHP/Debian-Indestructible/tree/main/sources]

#### 33. Update System

```bash
apt update && apt upgrade -y
```

#### 34. Install Additional Packages

```bash
tasksel --new-install
```

Select only:
- **Standard System Utilities**
- **SSH Server** (if needed)

#### 35. Install Network Manager

```bash
apt install -y network-manager avahi-daemon
apt install -y --no-install-recommends xdg-user-dirs xdg-utils
```

#### 36. Install Kernel and Firmware

**For sid/unstable:**
```bash
apt install -y linux-image-amd64 linux-headers-amd64 firmware-linux firmware-linux-nonfree dkms
```

**For stable (with backports kernel):**
```bash
apt install -t trixie-backports linux-image-amd64 linux-headers-amd64 firmware-linux firmware-linux-nonfree
```

### ZRAM Configuration

#### 37. Install ZRAM Tools

```bash
apt install -y zram-tools
```

#### 38. Configure ZRAM

```bash
sed -i "s/ALGO=lz4/ALGO=zstd/g; s/PERCENT=50/PERCENT=100/g; s/SIZE=512/#SIZE=512/g" /etc/default/zramswap
```

**What this does:**
- **ALGO=zstd**: Uses ZSTD compression (better ratio than LZ4)
- **PERCENT=100**: Uses 100% of RAM for ZRAM (effectively doubles usable memory)
- **SIZE commented out**: Lets ZRAM calculate optimal size automatically

**Example**: With 8 GB RAM and ZSTD compression achieving 2.5x ratio, you effectively have ~20 GB of usable memory.

#### 39. Verify ZRAM Configuration

```bash
cat /etc/default/zramswap
```

Should show:
```
ALGO=zstd
PERCENT=100
#SIZE=512
```

#### 40. Configure Network Manager

```bash
sed -i 's/^\(\[ifupdown\]\s*managed=\)false/\1true/' /etc/NetworkManager/NetworkManager.conf
```
Allow Network Manager to manage the system network connections.

#### 41. Configure locate Database

```bash
cat > /etc/updatedb.conf << EOF
PRUNE_BIND_MOUNTS="no"
PRUNENAMES=".git .bzr .hg .svn .snapshots"
PRUNEPATHS="/tmp /var/spool /var/lib/os-prober /var/lib/ceph /home/.ecryptfs /var/lib/schroot"
PRUNEFS="NFS afs autofs binfmt_misc ceph cgroup cgroup2 cifs coda configfs curlftpfs debugfs devfs devpts devtmpfs ecryptfs ftpfs fuse.ceph fuse.cryfs fuse.encfs fuse.glusterfs fuse.gocryptfs fuse.gvfsd-fuse fuse.mfs fuse.rclone fuse.rozofs fuse.sshfs fusectl fusesmb hugetlbfs iso9660 lustre lustre_lite mfs mqueue ncpfs nfs nfs4 ocfs ocfs2 proc pstore rpc_pipefs securityfs shfs smbfs sysfs tmpfs tracefs udev udf usbfs"
EOF
```

#### 42. Enable TRIM for SSDs

```bash
systemctl enable fstrim.timer
```

#### 43. Create User Account

```bash
useradd -m -G sudo,adm,audio,video,cdrom,dip,floppy,plugdev,netdev,users -s /bin/bash -c "User Full Name" username
passwd username
```

Replace `User Full Name` and `username` with your information.

#### 44. Set Root Password

```bash
passwd
```

#### 45. Define User Variable for Snapper

```bash
SNAPPER_USER=username
```

Replace `username` with the user you just created.

### Bootloader Installation

#### 46. Install GRUB Packages

```bash
apt install -y grub-efi-amd64 efibootmgr grub-efi-amd64-signed
```

#### 47. Disable Hibernation

Since we won't use hibernation, we explicitly disable it:

```bash
cat > /etc/initramfs-tools/conf.d/resume << EOF
RESUME=none
EOF
```

#### 48. Configure GRUB

```bash
cat > /etc/default/grub.d/custom.cfg << EOF
GRUB_TIMEOUT=3
GRUB_CMDLINE_LINUX_DEFAULT="splash quiet noresume"
EOF
```

The `noresume` parameter ensures the kernel doesn't attempt to resume from hibernation.

#### 49. Update Initramfs and GRUB

```bash
update-initramfs -u -k all
update-grub
```

#### 50. Install GRUB to ESP

**For normal installations:**
```bash
grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot/efi \
  --recheck
```

**For portable/USB devices:**
```bash
grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot/efi \
  --removable \
  --recheck
```

### GRUB-BTRFS Setup

#### 51. Clone and Configure grub-btrfs

```bash
cd ~/
git clone https://github.com/Antynea/grub-btrfs.git
cd grub-btrfs

sed -i.bkp \
  '/^#GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=/a \
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rd.live.overlay.overlayfs=1"' \
  config
```

#### 52. Install grub-btrfs

```bash
make install
systemctl enable grub-btrfsd.service
```

### Snapper Setup

#### 53. Unmount Snapshots Directory

```bash
cd /
umount /.snapshots
rm -r /.snapshots
```

#### 54. Create Snapper Configuration

```bash
snapper --no-dbus -c root create-config /
```

#### 55. Remount Snapshots Subvolume

```bash
btrfs su del .snapshots
mkdir /.snapshots
mount /.snapshots
```

#### 56. Configure Snapper for Root

```bash
snapper --no-dbus -c root set-config \
ALLOW_USERS=$SNAPPER_USER \
SYNC_ACL=yes \
TIMELINE_LIMIT_HOURLY=24 \
TIMELINE_LIMIT_DAILY=7 \
TIMELINE_LIMIT_WEEKLY=1 \
TIMELINE_LIMIT_MONTHLY=1 \
TIMELINE_LIMIT_YEARLY=0
```

#### 57. Optional: Configure Snapper for /home

```bash
snapper --no-dbus -c home create-config /home
snapper --no-dbus -c home set-config \
ALLOW_USERS=$SNAPPER_USER \
SYNC_ACL=yes \
TIMELINE_LIMIT_HOURLY=24 \
TIMELINE_LIMIT_DAILY=14 \
TIMELINE_LIMIT_WEEKLY=7 \
TIMELINE_LIMIT_MONTHLY=1 \
TIMELINE_LIMIT_YEARLY=0
```

#### 58. Enable Snapper Timers

```bash
systemctl disable snapper-boot.timer
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
```

#### 59. Install GRUB Rollback Plugin

Exit the chroot and install the plugin:

```bash
exit
mkdir -p /mnt/usr/lib/snapper/plugins
cp -r ~/Debian-Indestructible/snapper-plugins/99-rollback-grub /mnt/usr/lib/snapper/plugins
chmod +x /mnt/usr/lib/snapper/plugins/99-rollback-grub
```

**Learn more**: See [GRUB Rollback Plugin Documentation](https://github.com/JMarcosHP/Debian-Indestructible/blob/main/plugin-explanation.md) for details on how this critical component works.

### Finalize Installation

#### 60. Unmount Everything and Reboot

```bash
cd /
umount -vR /mnt
reboot
```

Remove the installation media when prompted.

## Post-Installation

### Install Desktop Environment

After your first boot, log in and install your desired desktop environment:

```bash
cd ~/
git clone https://github.com/JMarcosHP/Debian-Indestructible.git
cd ~/Debian-Indestructible
chmod +x ~/Debian-Indestructible/install-debian.sh
```

**Recommended installation order for Desktop:**

```bash
./install-debian.sh base
./install-debian.sh utilities
./install-debian.sh kde-desktop   # or gnome-desktop / xfce4-desktop
./install-debian.sh kde-flatpak   # Flatpak integration
./install-debian.sh kde-snapd     # Snapd integration
./install-debian.sh fcitx5-support-kde # Optional Input method support
./install-debian.sh restricted-extras # Codecs and proprietary software
./install-debian.sh gaming  # Optional gaming essentials
```

See the [main README](https://github.com/JMarcosHP/Debian-Indestructible#post-installation) for all available options.

### Verify ZRAM Status

Check that ZRAM is active and working:

```bash
sudo zramctl
```

Should show something like:
```
NAME       ALGORITHM DISKSIZE DATA COMPR TOTAL STREAMS MOUNTPOINT
/dev/zram0 zstd          7.7G   4K   80B   12K       4 [SWAP]
```

Check swap status:
```bash
free -h
```

You should see swap space equal to your RAM size.

### Monitor ZRAM Performance

View compression statistics:

```bash
cat /sys/block/zram0/mm_stat
```

This shows:
- Original data size
- Compressed data size
- Compression ratio
- Memory usage

### Take Your First Snapshot

```bash
sudo snapper -c root create --description "Fresh installation"
```

## Conclusion

Congratulations! You've built a high-performance Debian system that maximizes your RAM efficiency through ZRAM compression. Your system now features:

- Ultra-fast swap operations (no disk I/O)
- Extended effective RAM capacity (2-3x compression)
- Reduced SSD/eMMC wear
- Automatic snapshots before system changes
- Bootable snapshots from GRUB
- Easy rollback of failed upgrades

**ZRAM Benefits You'll Notice:**
- Smoother multitasking with limited RAM
- Faster application switching
- Reduced system freezing under memory pressure
- Extended SSD lifespan (no swap writes to disk)

**Remember:**
- **No hibernation support** with this configuration
- ZRAM performance scales with CPU cores (more cores = better compression throughput)
- Monitor ZRAM usage periodically to ensure adequate compression ratios
- Consider physical RAM upgrades if ZRAM swap usage consistently exceeds 50%

**Next steps:**
- Install your preferred desktop environment
- Configure applications and settings
- Set up backups (snapshots are NOT backups!)
- Read the [Rollback Guide](https://github.com/JMarcosHP/Debian-Indestructible/blob/main/rollbacks.md) to learn snapshot management

Welcome to your fast, efficient, and indestructible Debian system! 🚀

---

**Need help?** Check the [main documentation](https://github.com/JMarcosHP/Debian-Indestructible) or open an issue on [GitHub](https://github.com/JMarcosHP/Debian-Indestructible/issues).

**Pro Tip**: To temporarily disable ZRAM for testing, use `sudo swapoff /dev/zram0`. Re-enable with `sudo systemctl restart zramswap.service`.