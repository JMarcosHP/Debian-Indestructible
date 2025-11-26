# System Rollbacks with Snapper

> *Failure is not the end. It is a necessary part of the path - Eno Cordova*

## Table of Contents

- [Introduction](#introduction)
- [Understanding Snapshots](#understanding-snapshots)
- [Rollback Methods](#rollback-methods)
  - [Method 1: Boot from GRUB (Recommended)](#method-1-boot-from-grub-recommended)
  - [Method 2: Live Rollback from Snapshot List](#method-2-live-rollback-from-snapshot-list)
  - [Method 3: Pre-emptive Manual Snapshot](#method-3-pre-emptive-manual-snapshot)
- [Managing Snapshots](#managing-snapshots)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Video Demonstration](#video-demonstration)

## Introduction

One of the most powerful features of a Debian Indestructible system is the ability to **roll back to any previous state**. Whether you've installed broken software, applied a faulty update, or accidentally misconfigured your system, snapshots let you undo these changes with a single command.

This guide covers three methods for performing rollbacks, from the safest (booting into a read-only snapshot) to the most flexible (live system rollback).

## Understanding Snapshots

Snapper automatically creates several types of snapshots:

| Snapshot Type | When Created | Purpose |
|---------------|--------------|---------|
| **Timeline** | Hourly, daily, weekly, monthly | Regular automatic backups of system state |
| **Pre/Post APT** | Before and after package operations | Allows reverting failed updates or installations |
| **Manual** | When you run `snapper create` | Custom snapshots before risky operations |
| **Rollback** | After performing a rollback | Records the state you rolled back from |

Each snapshot is:
- **Immutable** - Cannot be modified once created
- **Space-efficient** - Only stores changed data (COW)
- **Bootable** - Can be booted directly using grub-btrfs
- **Numbered sequentially** - Starting from 1 (your initial system)

View all snapshots:
```bash
sudo snapper -c root list
```

Example output:
```
 # | Type   | Pre # | Date                     | User | Cleanup | Description           | Userdata
---+--------+-------+--------------------------+------+---------+-----------------------+---------
 0 | single |       |                          | root |         | current               |
 1 | single |       | 2024-01-15 10:30:00      | root |         | first root filesystem |
 2 | single |       | 2024-01-15 14:00:00      | root | timeline| timeline              |
 3 | pre    |       | 2024-01-16 09:15:00      | root | number  | apt                   |
 4 | post   |     3 | 2024-01-16 09:20:00      | root | number  | apt                   |
```

## Rollback Methods

### Method 1: Boot from GRUB (Recommended)

**This is the safest method** - the system is mounted read-only, preventing accidental changes that could corrupt the rollback.

#### When to Use
- After a failed system update that prevents normal boot
- When you want to test if a snapshot resolves your issue
- For critical rollbacks where safety is paramount
- When the current system is unstable

#### Step-by-Step Process

**1. Reboot your system**
```bash
sudo reboot
```

**2. Access GRUB menu**

When the GRUB menu appears, navigate to:
```
Debian GNU/Linux snapshots
  └─> Debian Snapshot #X (date/description)
```

Use arrow keys to select the desired snapshot and press Enter.

**3. Log into the read-only system**

The snapshot boots in **read-only mode**. Log in normally with your user credentials.

**Important**: Do NOT attempt to:
- Install or remove packages with `apt`
- Modify system files
- Run system updates
- Make any permanent changes

Any changes will be lost and could get your system into an inconsistent state.

**4. Verify the snapshot state**

Check that this is the state you want to restore:
```bash
# Check installed packages
dpkg -l | grep <package-name>
apt list --installed | grep <package-name>

# Check system files
cat /etc/some-config-file

# Test applications
<your-application> --version
```

**5. Perform the rollback**

If this snapshot resolves your issue, execute:
```bash
sudo snapper rollback
```

This command:
- Creates a new writable snapshot based on the current read-only one
- Configures it as the new default subvolume
- Triggers the GRUB rollback plugin

**6. Verify plugin execution**

Check the logs to ensure the rollback plugin executed successfully:
```bash
sudo cat /var/log/snapper.log
```

Look for entries like:
```
=== STARTING POST-ROLLBACK GRUB PLUGIN ===
Mounting the new default snapshot subvolume...
Running commands inside the chrooted subvolume...
=== GRUB POST-ROLLBACK PLUGIN FINISHED ===
```

**7. Verify GRUB configuration**

Ensure the bootloader points to the correct snapshot:
```bash
sudo cat /boot/efi/EFI/debian/grub.cfg
```

Should show the new default subvolume path.

**8. Reboot into the restored system**
```bash
sudo reboot
```

Your system is now restored to the selected snapshot state.

---

### Method 2: Live Rollback from Snapshot List

**Fast but requires immediate reboot** - changes made after rollback won't persist.

#### When to Use
- System is currently bootable and stable
- You know which snapshot number to restore
- You want a quick rollback without rebooting twice
- For reverting recent changes (hours or days ago)

#### Step-by-Step Process

**1. List available snapshots**
```bash
sudo snapper -c root list
```

Identify the snapshot number you want to restore. Look for:
- **Timeline snapshots** - Recent automatic backups
- **Pre-APT/Post-APT snapshots** - State before/after package changes
- **Manual snapshots** - Your custom snapshots

**2. Get snapshot details**

View detailed information about a specific snapshot:
```bash
sudo snapper -c root status 1..4
```

This shows file changes between snapshots 1 and 4.

**3. Execute the rollback**
```bash
sudo snapper -c root rollback <snapshot-number>
```

Example:
```bash
sudo snapper -c root rollback 3
```

The command:
- Creates a new read-write snapshot from the selected one
- Sets it as the new default subvolume
- Triggers the GRUB plugin to update bootloader

**4. Verify plugin execution**
```bash
sudo cat /var/log/snapper.log
```

Confirm successful execution with no errors.

**5. Verify GRUB configuration**
```bash
sudo cat /boot/efi/EFI/debian/grub.cfg | grep subvol
```

**6. Reboot immediately**

**Critical**: Reboot right away. Any changes you make now (installing packages, modifying files) will NOT be saved in the next restored snapshot.

```bash
sudo reboot
```

After reboot, your system will be in the restored snapshot state.

---

### Method 3: Pre-emptive Manual Snapshot

**Proactive protection** - create a safety net before risky operations.

#### When to Use
- Before installing experimental software
- Before major system configuration changes
- Before editing critical system files
- Before kernel updates on custom hardware
- Before applying third-party scripts or tweaks

#### Step-by-Step Process

**1. Create a manual snapshot with description**

Before making your changes:
```bash
sudo snapper -c root create --description "Before installing custom kernel"
```

This creates a new snapshot with a clear description of what you're about to do.

**2. Note the snapshot number**

The command outputs the new snapshot number:
```
snapshot 42 created
```

Remember this number (or use `snapper list` to find it later).

**3. Perform your risky operation**

Now make your changes:
```bash
# Install new software
sudo apt install foo

# Modify system config
sudo nano /etc/important-config

# Apply custom scripts
sudo ./experimental-setup.sh
```

**4. Test the changes**

Verify that your system works as expected:
- Reboot if necessary
- Test affected applications
- Check system stability
- Verify configurations

**5. If something goes wrong, rollback**

If your changes caused problems:
```bash
sudo snapper -c root list  # Find your snapshot number
sudo snapper -c root rollback 42  # Rollback to pre-change state
```

**6. Verify and reboot**

Check logs:
```bash
sudo cat /var/log/snapper.log
```

Verify GRUB config:
```bash
sudo cat /boot/efi/EFI/debian/grub.cfg | grep subvol
```

Reboot immediately:
```bash
sudo reboot
```

**7. If changes worked, keep the new state**

If everything is fine, you can delete the pre-change snapshot to save space:
```bash
sudo snapper -c root delete 42
```

Or keep it as a long-term backup:
```bash
sudo snapper -c root modify --cleanup-algorithm "" 42
```

This prevents automatic cleanup of the snapshot.

---

## Managing Snapshots

### Viewing Snapshot Details

**Compare two snapshots:**
```bash
sudo snapper -c root status 3..5
```

Shows what changed between snapshots 3 and 5.

**View file differences:**
```bash
sudo snapper -c root diff 3..5 /etc/apt/sources.list
```

Shows exact changes to a specific file.

**View snapshot info:**
```bash
sudo snapper -c root info 3
```

Displays metadata about snapshot 3.

### Creating Manual Snapshots

**Create with description:**
```bash
sudo snapper -c root create --description "Before system upgrade"
```

**Create pre/post pair manually:**
```bash
PRE=$(sudo snapper -c root create --type pre --print-number --description "Before change")
# Make your changes here
sudo snapper -c root create --type post --pre-number $PRE --description "After change"
```

### Deleting Snapshots

**Delete a single snapshot:**
```bash
sudo snapper -c root delete 42
```

**Delete a range:**
```bash
sudo snapper -c root delete 10-20
```

**Delete old timeline snapshots:**
```bash
sudo snapper -c root delete $(sudo snapper -c root list | grep timeline | head -n 10 | awk '{print $1}')
```

**Warning**: Never delete:
- Snapshot #0 (current system)
- Snapshot #1 (initial installation)
- Currently booted snapshot
- Snapshots you might need for rollback

### Modifying Snapshot Retention

**Keep a snapshot indefinitely:**
```bash
sudo snapper -c root modify --cleanup-algorithm "" 42
```

**Change description:**
```bash
sudo snapper -c root modify --description "Important milestone" 42
```

## Troubleshooting

### Rollback Plugin Didn't Execute

**Problem**: After rollback, GRUB menu shows an incorrect snapshot number.

**Solution**:
```bash
# Check if plugin exists
ls -la /usr/lib/snapper/plugins/99-rollback-grub

# Check if it's executable
sudo chmod +x /usr/lib/snapper/plugins/99-rollback-grub

# Check logs
sudo cat /var/log/snapper.log
```

### GRUB Menu Doesn't Show Snapshots

**Problem**: grub-btrfs menu is empty.

**Solution**:
```bash
# Regenerate GRUB config
sudo update-grub

# Check grub-btrfs service
sudo systemctl status grub-btrfsd.service

# Restart the service
sudo systemctl restart grub-btrfsd.service
```

### Snapshot Number Not Found

**Problem**: `snapshot not found` error.

**Solution**:
```bash
# List all snapshots
sudo snapper -c root list

# Ensure snapshot exists
sudo btrfs subvolume list / | grep snapshots
```

### System Won't Boot

**Problem**: Boot fails or loops.

**Solution**:
1. Check the system logs for errors on boot.
2. Boot from a live system
3. Mount your system:
```bash
sudo mount /dev/deviceX /mnt
sudo mount /dev/deviceX /mnt/boot/efi

for dir in dev proc sys run; do
    sudo mount -v --rbind "/${dir}" "/mnt/${dir}"
    sudo mount -v --make-rslave "/mnt/${dir}"
done
```

4. Chroot and fix:
```bash
sudo chroot /mnt /bin/bash
```

### Snapshot Takes Too Much Space

**Problem**: Running out of disk space due to snapshots.

**Solution**:
```bash
# View space usage
sudo btrfs filesystem df /
sudo btrfs filesystem usage /

# Delete old snapshots
sudo snapper -c root delete $(sudo snapper -c root list | grep timeline | tail -n +10 | awk '{print $1}')

# Adjust retention policy
sudo snapper -c root set-config TIMELINE_LIMIT_DAILY=3 TIMELINE_LIMIT_WEEKLY=1
```

## Best Practices

### 1. Regular Snapshot Hygiene
- Review snapshots monthly: `sudo snapper -c root list`
- Delete unnecessary old snapshots
- Keep important milestones marked with clear descriptions
- Adjust retention policies based on your usage

### 2. Test Rollbacks Periodically
Test rollbacks in non-critical situations:
- Boot old snapshots to verify they work
- Familiarize yourself with the process

### 3. Before Major Changes
Always create a manual snapshot:
```bash
sudo snapper -c root create --description "Before [what you're doing]"
```

Examples:
- "Before installing NVIDIA drivers"
- "Before migrating to Wayland"
- "Before major system upgrade"

### 4. Combine with External Backups
Remember: **Snapshots are NOT backups!**
- Snapshots protect against software issues
- Backups protect against hardware failure
- Use tools like Clonezilla, Syncthing for external backups

### 5. Monitor Disk Space
BTRFS snapshots share data, but changes accumulate:
```bash
# Check regularly
df -h /
sudo btrfs filesystem usage /
```

Keep at least 10-20% free space for optimal BTRFS performance.

### 6. BTRFS Maintenance
Sometimes BTRFS filesystems need maintenance, like balancing, scrubbing, or defragmenting.

Some good tools to automate this are:
- The `btrfsmaintenance` package, provides a configuration file to schedule regular maintenance tasks via systemd timers. Read the [btrfsmaintenance documentation](https://manpages.debian.org/unstable/btrfsmaintenance/btrfsmaintenance.8.en.html) for setup instructions.
- GUI tools like `btrfs-assistant` can help visualize and manage BTRFS filesystems, but their rollback functionality is currently incompatible with this BTRFS layout and may disrupt the Snapper snapshot scheme. An existing [GitLab issue](https://gitlab.com/btrfs-assistant/btrfs-assistant/-/issues?show=eyJpaWQiOiIxMzciLCJmdWxsX3BhdGgiOiJidHJmcy1hc3Npc3RhbnQvYnRyZnMtYXNzaXN0YW50IiwiaWQiOjE3NjY3NzA5MH0%3D) tracks this limitation, feel free to follow it or request this feature from the maintainers.

## Video Demonstration (Coming Soon)

Watch the rollback process using grub-btrfs in this video:

**[Debian Indestructible - System Rollback Tutorial](video-link-placeholder)**

This video demonstrates:
- Booting and rolling back from GRUB

---

## Final Notes

You now have three powerful methods to undo system changes:

| Method | Safety | Speed | Use Case |
|--------|--------|-------|----------|
| **Boot from GRUB** | ⭐⭐⭐ Safest | Slower (2 reboots) | Critical failures, testing snapshots |
| **Live Rollback** | ⭐⭐ Safe | Fast (1 reboot) | Quick recovery, known good snapshot |
| **Pre-emptive** | ⭐⭐⭐ Safest | Medium | Before risky operations |

**Key Takeaways:**
- Always check `/var/log/snapper.log` after rollbacks
- Reboot immediately after live rollbacks
- Never try to modify a booted snapshot
- Create manual snapshots before major changes
- Snapshots complement but don't replace backups

Your Debian system is now truly indestructible—almost any mistake can be undone with a few commands. Use this power wisely, experiment confidently, and enjoy the freedom of knowing you can always go back! 🛡️

---

**Need help?** Check the [main documentation](https://github.com/JMarcosHP/Debian-Indestructible) or open an issue on [GitHub](https://github.com/JMarcosHP/Debian-Indestructible/issues).