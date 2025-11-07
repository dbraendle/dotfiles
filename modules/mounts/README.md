# Mounts Module

Network mounts configuration module for macOS using autofs. Enables automatic mounting of NFS and SMB/CIFS network shares.

## Overview

This module configures macOS's built-in `autofs` system to automatically mount network shares when accessed. This approach provides:

- **On-demand mounting**: Shares are only mounted when accessed
- **Automatic unmounting**: Unused shares are unmounted after idle time
- **System integration**: Uses native macOS autofs infrastructure
- **Reliability**: Handles network unavailability gracefully

## How autofs Works

autofs is a kernel-based automounter that monitors special directories and mounts filesystems on-demand when accessed:

1. You configure mount points in `/etc/auto_master` (master map)
2. Each mount type has its own map file (e.g., `/etc/auto_nfs`, `/etc/auto_smb`)
3. When you access a mount point, autofs automatically mounts it
4. After idle time, autofs unmounts it automatically

### Example

If you configure an NFS mount for `/System/Volumes/Data/nfs/media`:
- The directory appears to exist but is not mounted
- When you run `ls /System/Volumes/Data/nfs/media`, autofs mounts it
- You can access files normally
- After ~10 minutes of inactivity, autofs unmounts it

## Configuration

### File Location

Configuration is stored in `mounts.config` in the **root of your dotfiles repository** (NOT in the module directory). This file is gitignored for security.

### Configuration Format

```
# Mounts Configuration
# Format: mountpoint|server|sharepath|type|options
#
# mountpoint: Full path where the share should appear (e.g., /System/Volumes/Data/nfs/media)
# server: IP address or hostname of the NFS/SMB server
# sharepath: Path to the share on the server
# type: Either "nfs" or "smb"
# options: Mount options (optional, defaults provided)

# NFS Example
/System/Volumes/Data/nfs/media|192.168.1.100|/volume1/media|nfs|resvport,bg,hard,intr

# SMB Example
/System/Volumes/Data/smb/backup|192.168.1.50|backup|smb|soft

# Another NFS Example with different options
/System/Volumes/Data/nfs/documents|nas.local|/exports/docs|nfs|resvport,soft,intr
```

### Configuration Rules

- **One mount per line**
- Lines starting with `#` are comments
- Empty lines are ignored
- Use pipe (`|`) as field separator
- Whitespace around fields is automatically trimmed

### Mount Point Paths

On modern macOS (Catalina+), use paths under `/System/Volumes/Data/` for user-accessible locations:

- **NFS mounts**: `/System/Volumes/Data/nfs/<name>`
- **SMB mounts**: `/System/Volumes/Data/smb/<name>`

These paths are accessible from `/nfs/<name>` and `/smb/<name>` via synthetic firmlinks.

### Mount Types

#### NFS (Network File System)

**Default options**: `resvport,bg,hard,intr`

Common options:
- `resvport`: Use a reserved port (required by many NFS servers)
- `bg`: Retry mounting in background if server unavailable
- `hard`: Keep retrying NFS requests (vs `soft`)
- `soft`: Give up after timeout
- `intr`: Allow interruption of NFS operations
- `rw`: Read-write (default)
- `ro`: Read-only

#### SMB/CIFS (Windows/Samba shares)

**Default options**: `soft`

Common options:
- `soft`: Fail after timeout rather than hanging
- `hard`: Keep retrying indefinitely
- `nobrowse`: Don't show in Finder sidebar (automatic for autofs)

### Example Configuration

```bash
# Copy example to create your configuration
cp mounts.config.example mounts.config

# Edit with your mount details
vim mounts.config
```

Example `mounts.config`:

```
# Home NAS - Media Files (NFS)
/System/Volumes/Data/nfs/media|192.168.1.100|/volume1/media|nfs|resvport,bg,hard,intr

# Home NAS - Backups (NFS, read-only)
/System/Volumes/Data/nfs/backups|192.168.1.100|/volume1/backups|nfs|resvport,ro,hard,intr

# Work Server - Shared Drive (SMB)
/System/Volumes/Data/smb/shared|workserver.local|shared|smb|soft

# Home NAS - Documents (NFS, soft mount)
/System/Volumes/Data/nfs/docs|nas.home.arpa|/documents|nfs|resvport,soft,intr
```

## Installation

```bash
# 1. Create configuration
cp mounts.config.example mounts.config
vim mounts.config  # Add your mounts

# 2. Install module
./install.sh mounts

# The installation will:
# - Validate your configuration
# - Create autofs map files (/etc/auto_nfs, /etc/auto_smb)
# - Update /etc/auto_master
# - Create mount point directories
# - Reload autofs
# - Test mounts
```

### What Gets Installed

- `/etc/auto_master`: Master autofs configuration (entry added)
- `/etc/auto_nfs`: NFS mount definitions (if NFS mounts configured)
- `/etc/auto_smb`: SMB mount definitions (if SMB mounts configured)
- Mount point directories (e.g., `/System/Volumes/Data/nfs/`)
- Backups of modified files in `~/.dotfiles-backups/mounts/`

## Usage

### Accessing Mounts

Simply access the mount point path:

```bash
# List files (triggers mount)
ls /System/Volumes/Data/nfs/media

# Navigate in Finder
open /System/Volumes/Data/nfs/media

# Use in commands
cp /System/Volumes/Data/nfs/media/video.mp4 ~/Downloads/
```

### Checking Mount Status

```bash
# Show active autofs mounts
mount | grep autofs

# Show all mounts
mount | grep -E '(nfs|smbfs)'

# Check autofs status
sudo automount -vc
```

### Manually Unmounting

```bash
# Unmount specific mount
sudo umount /System/Volumes/Data/nfs/media

# Unmount all autofs mounts
sudo automount -u
```

### Reloading Configuration

After changing `mounts.config`:

```bash
# Method 1: Use update script
./modules/mounts/update.sh

# Method 2: Manual reload
sudo automount -vc
```

## Updating

When you modify `mounts.config`:

```bash
# Reinstall to apply changes
./install.sh mounts

# Or use the update script
./modules/mounts/update.sh
```

The update will:
- Regenerate autofs configuration files
- Reload autofs without unmounting active shares

## Uninstallation

```bash
./uninstall.sh mounts
```

This will:
- Remove autofs configuration files
- Remove entries from `/etc/auto_master`
- Reload autofs
- Create backups before removal
- Preserve your `mounts.config` file
- Leave mount point directories in place

## Troubleshooting

### Mount Not Accessible

**Symptom**: `ls /System/Volumes/Data/nfs/media` times out or fails

**Possible causes**:
1. Network server is down or unreachable
2. Firewall blocking NFS/SMB ports
3. Incorrect server address or share path
4. Authentication required (SMB)

**Solutions**:
```bash
# Test network connectivity
ping 192.168.1.100

# Test NFS server
showmount -e 192.168.1.100

# Test SMB server
smbutil status 192.168.1.50

# Check autofs logs
log show --predicate 'process == "automountd"' --last 5m --info
```

### Permission Denied

**For NFS**:
- Check server export permissions
- Verify your user ID matches server permissions
- Try adding `nfsvers=4` option for NFSv4

**For SMB**:
- Add credentials to Keychain
- Or use URL format with credentials (not in config file!)

### Changes Not Taking Effect

```bash
# Force reload autofs
sudo automount -vc

# If that doesn't work, kill automount daemon
sudo killall automountd
# It will restart automatically

# Last resort: reboot
sudo reboot
```

### Debugging autofs

```bash
# Enable debug logging
sudo automount -cv

# Check what autofs sees
sudo automount -vc

# View autofs configuration
cat /etc/auto_master
cat /etc/auto_nfs
cat /etc/auto_smb

# Check for syntax errors
sudo automount -c
```

### Mount Hangs

If a mount hangs (server unreachable):

```bash
# Force unmount
sudo umount -f /System/Volumes/Data/nfs/media

# If that fails
sudo umount -f -l /System/Volumes/Data/nfs/media

# Kill hanging processes
sudo lsof +D /System/Volumes/Data/nfs/media | awk 'NR>1 {print $2}' | xargs sudo kill
```

## Security Notes

### Important Security Practices

1. **Never commit `mounts.config` to git**
   - Contains server IPs and network topology
   - May contain sensitive share names
   - File is gitignored by default

2. **Use local network addresses**
   - Prefer private IP ranges (192.168.x.x, 10.x.x.x)
   - Or use `.local` mDNS names
   - Avoid exposing internal network structure

3. **Don't store credentials in config**
   - For SMB authentication, use macOS Keychain
   - Or connect once via Finder to save credentials
   - Never put passwords in `mounts.config`

4. **Backup security**
   - Backups in `~/.dotfiles-backups/mounts/` may contain IPs
   - Don't share backup files
   - Backups have user-only permissions

5. **Use read-only where appropriate**
   - Add `ro` option for mounts that don't need write access
   - Reduces risk of accidental data modification

### Example Secure Configuration

```bash
# Good: Uses private IP and descriptive name
/System/Volumes/Data/nfs/media|192.168.1.100|/volume1/media|nfs|resvport,ro

# Good: Uses mDNS local name
/System/Volumes/Data/nfs/docs|nas.local|/documents|nfs|resvport,soft

# Bad: Exposes public IP or sensitive paths
# /System/Volumes/Data/nfs/secret|203.0.113.50|/confidential|nfs|resvport
```

## Technical Details

### File Structure

```
modules/mounts/
├── module.json       # Module metadata
├── install.sh        # Installation script
├── update.sh         # Update/reload script
├── uninstall.sh      # Removal script
└── README.md         # This file

# In repository root:
mounts.config.example # Example configuration
mounts.config         # Your configuration (gitignored)
```

### Dependencies

- macOS (Darwin)
- `automount` command (built into macOS)
- `sudo` access for `/etc` modifications

### Compatibility

- Tested on macOS Monterey (12.x) and newer
- Should work on macOS Catalina (10.15) and newer
- Requires modern macOS with `/System/Volumes/Data/` structure

### autofs File Locations

- Master map: `/etc/auto_master`
- NFS map: `/etc/auto_nfs`
- SMB map: `/etc/auto_smb`
- Daemon: `/usr/sbin/automount`
- Logs: `log show --predicate 'process == "automountd"'`

## References

- [Apple autofs documentation](https://developer.apple.com/library/archive/documentation/Darwin/Reference/ManPages/man5/autofs.5.html)
- [autofs man page](https://ss64.com/osx/autofs.html)
- [NFS options](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man5/nfs.5.html)
- [SMB mounting](https://support.apple.com/guide/mac-help/connect-mac-shared-computers-servers-mchlp1140/)

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review autofs logs
3. Verify network connectivity to servers
4. Test manual mounting first
5. Check server-side export/share configuration
