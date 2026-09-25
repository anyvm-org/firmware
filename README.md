# firmware

Firmware images that [anyvm](https://github.com/anyvm-org/anyvm) downloads
on demand, published as release assets.

Nothing here is built or patched, and no image is committed to git.
`fetch.sh` downloads each image's upstream distribution package, copies the
image out of it unmodified and checks both the package and the image
against sha256 pins, so a release can only ever carry exactly these bytes.
Every image is published with a `.sha256` sidecar and the license file of
the package it came from.

## QEMU_EFI-2026.05-2ubuntu2.fd (aarch64 UEFI)

`/usr/share/qemu-efi-aarch64/QEMU_EFI.fd` from Ubuntu's `qemu-efi-aarch64`
2026.05-2ubuntu2 package, i.e. edk2-stable202605
([source](https://launchpad.net/ubuntu/+source/edk2/2026.05-2ubuntu2)).

edk2 builds 2025.08 through 2026.04 hang under QEMU `-cpu max` right after
the firmware banner: the new LPA2 support switches the MMU to the 52-bit
table format while ArmVirtQemu still runs on its 48-bit early page tables
([tianocore/edk2#11962](https://github.com/tianocore/edk2/issues/11962),
fixed by [b8df7d9c8e](https://github.com/tianocore/edk2/commit/b8df7d9c8e)).
Ubuntu 26.04 ships 2025.11
([LP: #2167864](https://bugs.launchpad.net/ubuntu/+source/edk2/+bug/2167864)).
anyvm boots this image instead only when the host's own firmware is one of
those builds, or when asked to with `--pinned-firmware`.

| file | sha256 |
| --- | --- |
| `qemu-efi-aarch64_2026.05-2ubuntu2_all.deb` | `240dcb7cc831156bae6c36945fd3a33738068ad96a7da3fa9ed41576df3259a0` |
| `QEMU_EFI-2026.05-2ubuntu2.fd` | `0329acaa424591d81f7c5f744af1625a021d0bb37da6784a2a8ae68066fe4527` |

The package pin was checked against the archive on 2026-09-24: its SHA512
is the one listed in the Packages index of Ubuntu 26.10 (stonking), which
the archive-signed InRelease covers.

License: `QEMU_EFI-2026.05-2ubuntu2.copyright` in the release, the
package's Debian copyright file (edk2 is BSD-2-Clause-Patent; it lists the
bundled third-party code and its licenses too).

## Releasing

`.github/workflows/release.yml` runs `fetch.sh` on every push, so a moved
source or a broken pin fails before anything is tagged. Pushing a `v*` tag
also publishes the staged files as that tag's release assets. To check
locally (needs curl and dpkg-deb):

```sh
sh fetch.sh dist
```
