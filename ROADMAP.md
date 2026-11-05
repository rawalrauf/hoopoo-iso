# Hoopoo ISO Roadmap

## Recently Completed

- ✅ Offline package mirror bundling
- ✅ GPG signature verification during build
- ✅ Node.js binary bundling for offline installation
- ✅ Stable and edge channel support
- ✅ Local source testing with `--local-source`
- ✅ Docker-based reproducible builds

## Current State

**Approach:** Traditional package installation (mkarchiso-based)
- Installation time: 5-15 minutes
- Fully offline capable
- Includes complete package mirror
- Uses standard Arch installation flow

## Planned Improvements

### Installation Experience (Next 3-6 months)

**Dual-boot support** - Install alongside existing OS (typically Windows)
- Detect existing partitions and free space
- Create encrypted Hoopoo partition in available space
- Handle shared ESP with existing OS
- Configure bootloader for dual-boot
- See: `plans/dual-boot.md`

**Secure Boot support** - Work on consumer hardware with Secure Boot enabled
- Microsoft-signed shim for first-stage boot
- Machine Owner Key (MOK) enrollment during install
- Sign kernel and bootloader components
- Unified Kernel Image (UKI) support
- See: `plans/consumer-secure-boot.md`

### Advanced Installation Options (6-12 months)

**OEM/Pre-installation mode** - Factory installation support
- Unattended installation from configuration file
- Pre-configure system settings
- Skip interactive questions
- Suitable for bulk deployments
- See: `plans/oem-install.md`

**Protected partition install** - Preserve user data during reinstalls
- Separate home partition that survives reinstalls
- Incremental system updates
- Rollback capability
- See: `plans/protected-partition-install.md`

### Architecture Expansion (12+ months)

**aarch64 support** - ARM64 ISO for modern ARM devices
- Apple Silicon Macs
- Snapdragon X Elite laptops
- ARM servers (AWS Graviton, Ampere)
- Requires: ARM build infrastructure, hardware-specific drivers
- See: `plans/aarch64-support.md`

### Infrastructure Improvements (ongoing)

**Automated testing**
- VM-based installation testing
- Test matrix for different scenarios (UEFI/BIOS, encryption on/off, dual-boot)
- Automated smoke tests post-install

**Nightly builds**
- Automated ISO builds from edge channel
- Continuous testing of latest packages
- Faster feedback on package issues

**Build optimizations**
- Faster package downloads with parallel fetching
- Better caching between builds
- Incremental updates to offline mirror

---

This roadmap focuses on improving the installation experience and supporting more hardware configurations. The traditional package installation approach works well and will be retained, with improvements focused on flexibility and hardware compatibility.
