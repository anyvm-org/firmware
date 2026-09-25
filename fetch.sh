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

# aarch64 UEFI: edk2-stable202605 as packaged by Ubuntu. edk2 builds
# 2025.08 - 2026.04 hang under QEMU -cpu max right after the firmware banner
# (tianocore/edk2#11962, fixed by b8df7d9c8e); Ubuntu 26.04 ships 2025.11
# (LP: #2167864). The archive pool keeps only current versions;
# snapshot.ubuntu.com and Launchpad keep every published one.
DEB=qemu-efi-aarch64_2026.05-2ubuntu2_all.deb
fetch "$DEB" 240dcb7cc831156bae6c36945fd3a33738068ad96a7da3fa9ed41576df3259a0 \
  "http://archive.ubuntu.com/ubuntu/pool/main/e/edk2/$DEB" \
  "https://snapshot.ubuntu.com/ubuntu/20260924T000000Z/pool/main/e/edk2/$DEB" \
  "https://launchpad.net/ubuntu/+archive/primary/+files/$DEB"
extract "$DEB" ./usr/share/qemu-efi-aarch64/QEMU_EFI.fd QEMU_EFI-2026.05-2ubuntu2.fd \
  0329acaa424591d81f7c5f744af1625a021d0bb37da6784a2a8ae68066fe4527
# The package's license file (edk2 plus its bundled third-party code) goes
# out with the image.
dpkg-deb --fsys-tarfile "$out/.fetch/$DEB" |
  tar -xO ./usr/share/doc/qemu-efi-aarch64/copyright > "$out/QEMU_EFI-2026.05-2ubuntu2.copyright"
