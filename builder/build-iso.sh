#!/bin/bash

set -e

# Note that these are packages installed to the Arch container used to build the ISO.
pacman-key --init
pacman-key --populate archlinux
pacman --noconfirm -Sy archlinux-keyring
pacman --noconfirm -Sy archiso git sudo base-devel jq grub

# Import Hoopoo GPG key so hoopoo mirror packages are verified during ISO builds
pacman-key --add /builder/hoopoo.gpg
pacman-key --lsign-key 070030E5D914817BA797F66AAF1C8F036A5E73FD
pacman --config /configs/pacman-online-${HOOPOO_MIRROR}.conf --noconfirm -Sy hoopoo-keyring
pacman-key --populate hoopoo

# Setup build locations
build_cache_dir="/var/cache"
offline_mirror_dir="$build_cache_dir/airootfs/var/cache/hoopoo/mirror/offline"
mkdir -p $build_cache_dir/
mkdir -p $offline_mirror_dir/

# We base our ISO on the official arch ISO (releng) config
cp -r /usr/share/archiso/configs/releng/* $build_cache_dir/
rm "$build_cache_dir/airootfs/etc/motd"

# Avoid using reflector for mirror identification as we are relying on the global CDN
rm -rf "$build_cache_dir/airootfs/etc/systemd/system/multi-user.target.wants/reflector.service"
rm -rf "$build_cache_dir/airootfs/etc/systemd/system/reflector.service.d"
rm -rf "$build_cache_dir/airootfs/etc/xdg/reflector"

# Bring in our configs
cp -r /configs/* $build_cache_dir/

# Persist HOOPOO_MIRROR so it's available at install time
echo "$HOOPOO_MIRROR" > "$build_cache_dir/airootfs/root/hoopoo_mirror"

# Setup Hoopoo itself
if [[ -d /hoopoo ]]; then
  cp -rp /hoopoo "$build_cache_dir/airootfs/root/hoopoo"
else
  git clone -b $HOOPOO_INSTALLER_REF https://github.com/$HOOPOO_INSTALLER_REPO.git "$build_cache_dir/airootfs/root/hoopoo"
fi

# Make log uploader available in the ISO too
mkdir -p "$build_cache_dir/airootfs/usr/local/bin/"
cp "$build_cache_dir/airootfs/root/hoopoo/bin/hoopoo-upload-log" "$build_cache_dir/airootfs/usr/local/bin/hoopoo-upload-log"

# Copy the Hoopoo Plymouth theme to the ISO
mkdir -p "$build_cache_dir/airootfs/usr/share/plymouth/themes/hoopoo"
cp -r "$build_cache_dir/airootfs/root/hoopoo/default/plymouth/"* "$build_cache_dir/airootfs/usr/share/plymouth/themes/hoopoo/"

# Download and verify Node.js binary for offline installation
NODE_DIST_URL="https://nodejs.org/dist/latest"

# Get checksums and parse filename and SHA
NODE_SHASUMS=$(curl -fsSL "$NODE_DIST_URL/SHASUMS256.txt")
NODE_FILENAME=$(echo "$NODE_SHASUMS" | grep "linux-x64.tar.gz" | awk '{print $2}')
NODE_SHA=$(echo "$NODE_SHASUMS" | grep "linux-x64.tar.gz" | awk '{print $1}')

# Download the tarball
curl -fsSL "$NODE_DIST_URL/$NODE_FILENAME" -o "/tmp/$NODE_FILENAME"

# Verify SHA256 checksum
echo "$NODE_SHA /tmp/$NODE_FILENAME" | sha256sum -c - || {
    echo "ERROR: Node.js checksum verification failed!"
    exit 1
}

# Copy to ISO
mkdir -p "$build_cache_dir/airootfs/opt/packages/"
cp "/tmp/$NODE_FILENAME" "$build_cache_dir/airootfs/opt/packages/"

# Add our additional packages to packages.x86_64
arch_packages=(linux-t2 git gum jq openssl plymouth tzupdate lvm2 cryptsetup parted hoopoo-keyring)
printf '%s\n' "${arch_packages[@]}" >>"$build_cache_dir/packages.x86_64"

# Build list of all the packages needed for the offline mirror
all_packages=($(cat "$build_cache_dir/packages.x86_64"))
all_packages+=($(grep -v '^#' "$build_cache_dir/airootfs/root/hoopoo/install/hoopoo-base.packages" | grep -v '^$'))
all_packages+=($(grep -v '^#' "$build_cache_dir/airootfs/root/hoopoo/install/hoopoo-other.packages" | grep -v '^$'))
all_packages+=($(grep -v '^#' /builder/archinstall.packages | grep -v '^$'))

# TEMPORARY: apple-bcm-firmware is not yet indexed in the arch-mact2 pacman db
# so we bundle it manually from builder/t2-packages/ and exclude it from pacman download.
# To remove this fix once it's properly indexed:
#   1. Verify it's indexed: curl -s https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release/arch-mact2.db | zstd -d | tar -t | grep apple-bcm-firmware
#   2. Delete builder/t2-packages/apple-bcm-firmware-*.pkg.tar.zst (and directory if empty)
#   3. Remove the all_packages exclusion line below
#   4. Remove the cp /builder/t2-packages line below
#   Note: hoopoo-other.packages already has apple-bcm-firmware — no changes needed there
all_packages=($(printf '%s\n' "${all_packages[@]}" | grep -v '^apple-bcm-firmware$'))

# Download all the packages to the offline mirror inside the ISO
mkdir -p /tmp/offlinedb
pacman --config /configs/pacman-online-${HOOPOO_MIRROR}.conf --noconfirm -Syw "${all_packages[@]}" --cachedir $offline_mirror_dir/ --dbpath /tmp/offlinedb

cp /builder/t2-packages/*.pkg.tar.zst "$offline_mirror_dir/"

repo-add --new "$offline_mirror_dir/offline.db.tar.gz" "$offline_mirror_dir/"*.pkg.tar.zst

# Create a symlink to the offline mirror instead of duplicating it.
# mkarchiso needs packages at /var/cache/hoopoo/mirror/offline in the container,
# but they're actually in $build_cache_dir/airootfs/var/cache/hoopoo/mirror/offline
mkdir -p /var/cache/hoopoo/mirror
ln -s "$offline_mirror_dir" "/var/cache/hoopoo/mirror/offline"

# Copy the offline pacman.conf to the ISO's /etc directory so the live environment uses our
# same config when booted. 
cp $build_cache_dir/pacman-offline.conf "$build_cache_dir/airootfs/etc/pacman.conf"

# Finally, we assemble the entire ISO
mkarchiso -v -w "$build_cache_dir/work/" -o "/out/" "$build_cache_dir/"

# Fix ownership of output files to match host user
if [ -n "$HOST_UID" ] && [ -n "$HOST_GID" ]; then
    chown -R "$HOST_UID:$HOST_GID" /out/
fi
