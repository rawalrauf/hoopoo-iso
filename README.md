# Hoopoo ISO

The Hoopoo ISO provides a streamlined installation experience for Hoopoo. It bundles an offline package mirror, includes the Hoopoo installer, and handles the complete system setup from boot to ready desktop.

## Downloading the latest ISO

Download from [iso.hoopoo.net](https://iso.hoopoo.net).

### Verify the download

Verify the ISO before writing it to installation media:

```bash
# Download ISO and checksums
curl -fLO "https://iso.hoopoo.net/hoopoo-latest.iso"
curl -fsSLO "https://iso.hoopoo.net/hoopoo-latest.iso.sha256"

# Verify checksum
sha256sum -c hoopoo-latest.iso.sha256

# Verify GPG signature (optional)
curl -fsSLO "https://iso.hoopoo.net/hoopoo-latest.iso.sig"
gpg --keyserver hkps://keys.openpgp.org --recv-keys D3931CBE26A484582489EEB7394AFBE6E502DB8F
gpg --verify hoopoo-latest.iso.sig hoopoo-latest.iso
```

## Installation

1. Write the ISO to a USB drive using balenaEtcher, Ventoy, or `dd`
2. Boot from the USB drive
3. Follow the Hoopoo Configurator prompts
4. The installer will set up the system automatically

Installation typically takes 5-15 minutes depending on hardware.

## For Maintainers

The following sections cover building, testing, and publishing the ISO.

## Building the ISO

Run `./bin/hoopoo-iso-make` and the output goes into `./release/`. 

### Build Options

```bash
# Standard build (uses stable channel)
./bin/hoopoo-iso-make

# Build with edge packages for testing
./bin/hoopoo-iso-make --dev

# Build with local installer and packages checkouts
./bin/hoopoo-iso-make --local-source ~/path/to/hoopoo ~/path/to/hoopoo-pkgs

# Build without using package cache
./bin/hoopoo-iso-make --no-cache

# Build with debug output
./bin/hoopoo-iso-make --debug
```

### Environment Variables

Customize the installer source:

- `HOOPOO_INSTALLER_REPO` - GitHub repository for the installer (default: `rawalrauf/hoopoo`)
- `HOOPOO_INSTALLER_REF` - Git ref (branch/tag) for the installer (default: `main`)
- `HOOPOO_MIRROR` - Package channel to use (default: `stable`, or `edge` with `--dev`)

Example:
```bash
HOOPOO_INSTALLER_REPO="myuser/hoopoo-fork" HOOPOO_INSTALLER_REF="feature-branch" ./bin/hoopoo-iso-make
```

## Testing the ISO

Boot the ISO in a VM for testing:

```bash
./bin/hoopoo-iso-boot release/hoopoo-main.iso
```

This uses QEMU to boot the ISO. Test the full installation flow before publishing.

## Publishing the ISO

### Sign the ISO

```bash
./bin/hoopoo-iso-sign <gpg-key-id> release/hoopoo-main.iso
```

This creates `.sig` and `.sha256` files alongside the ISO.

### Upload to iso.hoopoo.net

Upload requires rclone configured with R2 credentials:

```bash
rclone config  # Configure R2 remote if not already done
./bin/hoopoo-iso-upload release/hoopoo-main.iso
```

This uploads the ISO and its checksums/signatures to the configured R2 bucket.

## How the ISO Works

### Build Process

1. **Base ISO** - Starts with Arch Linux releng profile
2. **Offline Mirror** - Downloads all packages to bundled offline mirror
3. **Hoopoo Installer** - Includes installer from GitHub repository
4. **Node.js Binary** - Bundles Node.js for offline installation
5. **Configuration** - Adds Hoopoo-specific configs and scripts
6. **Assembly** - Creates bootable ISO with mkarchiso

### Installation Process

1. **Boot** - ISO boots into live environment
2. **Configuration** - User answers setup questions (hostname, user, timezone, etc.)
3. **Partitioning** - Disk is partitioned (supports encryption, LVM)
4. **Base Install** - Base system installed from bundled packages
5. **Hoopoo Setup** - Hoopoo packages and configs installed
6. **User Creation** - User account created and provisioned
7. **Boot Setup** - Bootloader configured
8. **Finalization** - System configured and ready to boot

### Offline Mirror

The ISO bundles a complete package mirror for offline installation:
- All base system packages
- Hoopoo-specific packages from pkgs.hoopoo.net
- Dependencies for the installer

Packages are verified with GPG signatures during build and installation.

## Repository Structure

```
bin/                    Build and test scripts
builder/                ISO build scripts (run inside Docker)
configs/                ISO configuration files
  airootfs/            Files copied to the live environment
  pacman-online-*.conf Pacman configs for building (with network)
  pacman-offline.conf  Pacman config for live ISO (offline mirror)
  profiledef.sh        ISO profile definition
plans/                 Future improvements and feature plans
release/               Build output (ISOs, not tracked in git)
README.md              This file
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) for planned improvements.
