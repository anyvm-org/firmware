#!/bin/sh
# Stages the release assets of anyvm-org/firmware in the directory given as
# $1 (default: dist). Nothing is built or patched: each image is copied out
# of an upstream distribution package, and both the package and the image
# are pinned by sha256 below, so a release can only ever carry these bytes.
set -eu

out=${1:-dist}
mkdir -p "$out/.fetch"

# fetch <deb> <sha256> <url>...: saves the first copy that matches the pin
# as $out/.fetch/<deb>.
fetch() {
  deb=$1
  sum=$2
  shift 2
  for url in "$@"; do
    if curl -fsSL --retry 3 --connect-timeout 30 -o "$out/.fetch/$deb" "$url" &&
       echo "$sum  $out/.fetch/$deb" | sha256sum -c --status; then
      echo "fetched $deb from $url"
      return 0
    fi
    echo "warning: no verified $deb from $url" >&2
  done
  echo "error: no source delivered $deb with sha256 $sum" >&2
  return 1
}

# extract <deb> <member> <asset> <sha256>: copies one file out of the
# package and moves it to $out/<asset> only once it matches its pin, next
# to an <asset>.sha256 sidecar.
extract() {
  dpkg-deb --fsys-tarfile "$out/.fetch/$1" | tar -xO "$2" > "$out/.fetch/$3"
  echo "$4  $out/.fetch/$3" | sha256sum -c -
  mv "$out/.fetch/$3" "$out/$3"
  (cd "$out" && sha256sum "$3" > "$3.sha256")
}

# license <deb> <member> <name>: the package's license file (edk2 plus its
# bundled third-party code) goes out with the image, as $out/<name>.copyright.
license() {
  dpkg-deb --fsys-tarfile "$out/.fetch/$1" | tar -xO "$2" > "$out/$3.copyright"
}

# aarch64 UEFI. edk2 builds 2025.08 - 2026.04 hang under QEMU -cpu max right
# after the firmware banner (tianocore/edk2#11962, fixed by b8df7d9c8e);
# Ubuntu 26.04 ships 2025.11 (LP: #2167864). The archive pool keeps only
# current versions; snapshot.ubuntu.com and Launchpad keep every published
# one.

# edk2-stable202605 as packaged by Ubuntu 26.10, the first build with that
# fix. On QEMU 10.2.1 it raises a Synchronous Exception when the loaders of
# FreeBSD 12.4 (loader.efi) and openEuler 22.03-LTS-SP4 (GRUB 2.06) hand
# over to the kernel.
DEB=qemu-efi-aarch64_2026.05-2ubuntu2_all.deb
fetch "$DEB" 240dcb7cc831156bae6c36945fd3a33738068ad96a7da3fa9ed41576df3259a0 \
  "http://archive.ubuntu.com/ubuntu/pool/main/e/edk2/$DEB" \
  "https://snapshot.ubuntu.com/ubuntu/20260924T000000Z/pool/main/e/edk2/$DEB" \
  "https://launchpad.net/ubuntu/+archive/primary/+files/$DEB"
extract "$DEB" ./usr/share/qemu-efi-aarch64/QEMU_EFI.fd QEMU_EFI-2026.05-2ubuntu2.fd \
  0329acaa424591d81f7c5f744af1625a021d0bb37da6784a2a8ae68066fe4527
license "$DEB" ./usr/share/doc/qemu-efi-aarch64/copyright QEMU_EFI-2026.05-2ubuntu2

# edk2-stable202402 as packaged by Ubuntu 24.04 (noble-updates): older than
# the LPA2 code, and it boots both of those guests on QEMU 10.2.1.
DEB=qemu-efi-aarch64_2024.02-2ubuntu0.9_all.deb
fetch "$DEB" 50d7c5f780f215db81677e08d21e681b61295ffe9040429cff9d9c2a0d03fe3d \
  "http://archive.ubuntu.com/ubuntu/pool/main/e/edk2/$DEB" \
  "https://snapshot.ubuntu.com/ubuntu/20260924T000000Z/pool/main/e/edk2/$DEB" \
  "https://launchpad.net/ubuntu/+archive/primary/+files/$DEB"
extract "$DEB" ./usr/share/qemu-efi-aarch64/QEMU_EFI.fd QEMU_EFI-2024.02-2ubuntu0.9.fd \
  8ff1fb8da2d8baf739bfdf020ff9ede225172c3a1b9d98e64e2b7935fd5ad4ab
license "$DEB" ./usr/share/doc/qemu-efi-aarch64/copyright QEMU_EFI-2024.02-2ubuntu0.9
