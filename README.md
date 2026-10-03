# firmware

Firmware images that [anyvm](https://github.com/anyvm-org/anyvm) and the
anyvm-org image builders download on demand, published as release assets.

Nothing here is built or patched, and no image is committed to git.
`fetch.sh` downloads each image's upstream distribution package, copies the
image out of it unmodified and checks both the package and the image
against sha256 pins, so a release can only ever carry exactly these bytes.
Every image is published with a `.sha256` sidecar and the license file of
the package it came from.

## aarch64 UEFI

edk2 builds 2025.08 through 2026.04 hang under QEMU `-cpu max` right after
the firmware banner: the new LPA2 support switches the MMU to the 52-bit
table format while ArmVirtQemu still runs on its 48-bit early page tables
([tianocore/edk2#11962](https://github.com/tianocore/edk2/issues/11962),
fixed by [b8df7d9c8e](https://github.com/tianocore/edk2/commit/b8df7d9c8e)).
Ubuntu 26.04 ships 2025.11
([LP: #2167864](https://bugs.launchpad.net/ubuntu/+source/edk2/+bug/2167864)).
2026.05, the first build with the fix, raises a `Synchronous Exception` on
QEMU 10.2.1 when the loaders of FreeBSD 12.4 (`loader.efi`) and openEuler
22.03-LTS-SP4 (GRUB 2.06) hand over to the kernel.

anyvm therefore boots `QEMU_EFI-2024.02-2ubuntu0.9.fd` instead whenever the
host's own firmware is a 2025.08 or later build. Passing an asset's URL to
anyvm's `--firmware` uses that image on any host.

The image builders (`build.py`, generated from
[base-builder](https://github.com/anyvm-org/base-builder)) apply the same
rule with `AAVMF_CODE.no-secboot-2024.02-2ubuntu0.9.fd`, the CODE image
they booted on the ubuntu-24.04 runners, so their aarch64 builds keep that
firmware on ubuntu-26.04.

License: each image's `.copyright` file in the release, the package's
Debian copyright file (edk2 is BSD-2-Clause-Patent; it lists the bundled
third-party code and its licenses too).

### QEMU_EFI-2024.02-2ubuntu0.9.fd

`/usr/share/qemu-efi-aarch64/QEMU_EFI.fd` from Ubuntu 24.04's
`qemu-efi-aarch64` 2024.02-2ubuntu0.9 package (noble-updates), i.e.
edk2-stable202402
([source](https://launchpad.net/ubuntu/+source/edk2/2024.02-2ubuntu0.9)).
It predates the LPA2 code and boots both of those guests on QEMU 10.2.1.

| file | sha256 |
| --- | --- |
| `qemu-efi-aarch64_2024.02-2ubuntu0.9_all.deb` | `50d7c5f780f215db81677e08d21e681b61295ffe9040429cff9d9c2a0d03fe3d` |
| `QEMU_EFI-2024.02-2ubuntu0.9.fd` | `8ff1fb8da2d8baf739bfdf020ff9ede225172c3a1b9d98e64e2b7935fd5ad4ab` |

The package pin was checked against the archive on 2026-09-25: its SHA256
and SHA512 are the ones listed in the noble-updates Packages index, which
the archive-signed InRelease covers.

### AAVMF_CODE.no-secboot-2024.02-2ubuntu0.9.fd

`/usr/share/AAVMF/AAVMF_CODE.no-secboot.fd` (the target of
`AAVMF_CODE.fd`) from the same package: the pflash CODE image without
Secure Boot, padded to the 64 MiB flash size. It is a separate build from
`QEMU_EFI.fd` above, not a padded copy of it. Its VARS companion,
`AAVMF_VARS.fd`, is byte-identical in this package and in Ubuntu 26.04's
2025.11-3ubuntu7.2, so it is not published here.

| file | sha256 |
| --- | --- |
| `qemu-efi-aarch64_2024.02-2ubuntu0.9_all.deb` | `50d7c5f780f215db81677e08d21e681b61295ffe9040429cff9d9c2a0d03fe3d` |
| `AAVMF_CODE.no-secboot-2024.02-2ubuntu0.9.fd` | `4a4cb7f6d8106bb2a7dd8c763fab14b1810152136fc4304e5b728f0043e84f12` |

### QEMU_EFI-2026.05-2ubuntu2.fd

`/usr/share/qemu-efi-aarch64/QEMU_EFI.fd` from Ubuntu's `qemu-efi-aarch64`
2026.05-2ubuntu2 package, i.e. edk2-stable202605
([source](https://launchpad.net/ubuntu/+source/edk2/2026.05-2ubuntu2)).

| file | sha256 |
| --- | --- |
| `qemu-efi-aarch64_2026.05-2ubuntu2_all.deb` | `240dcb7cc831156bae6c36945fd3a33738068ad96a7da3fa9ed41576df3259a0` |
| `QEMU_EFI-2026.05-2ubuntu2.fd` | `0329acaa424591d81f7c5f744af1625a021d0bb37da6784a2a8ae68066fe4527` |

The package pin was checked against the archive on 2026-09-24: its SHA512
is the one listed in the Packages index of Ubuntu 26.10 (stonking), which
the archive-signed InRelease covers.

## Releasing

`.github/workflows/release.yml` runs `fetch.sh` on every push, so a moved
source or a broken pin fails before anything is tagged. Pushing a `v*` tag
also publishes the staged files as that tag's release assets. To check
locally (needs curl and dpkg-deb):

```sh
sh fetch.sh dist
```
