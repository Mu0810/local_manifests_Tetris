# LineageOS 24.0 for the CMF Phone 1 (Tetris)

Local manifest and build scripts for an **unofficial LineageOS 24.0 (Android 17)** build
for the CMF Phone 1 (`Tetris`, MediaTek Dimensity 7300 / MT6878).

The device, vendor and kernel trees are the community trees maintained at
[github.com/CMF-Phone-1](https://github.com/CMF-Phone-1). This repo adds what is needed to
build them as LineageOS: a local manifest, a post-sync patch step and a build script.

> **Status: experimental.** Builds of this exact setup have not yet been booted on hardware.

## Contents

| File | Purpose |
|---|---|
| `tetris.xml` | Local manifest: device/vendor/kernel trees, MediaTek common, Dolby |
| `apply-patches.sh` | Run after every sync: retargets the device tree to LineageOS, applies `patches/` |
| `build.sh` | End to end: `repo init` (if needed), sync, patch, `breakfast Tetris`, `m bacon` |
| `patches/` | Patches applied automatically, laid out by project path |
| `pending/` | Patches that are needed but do not apply to Android 17 yet (see below) |

## Build

Needs x86_64 Linux, roughly 400 GB of disk and 32-64 GB of RAM (see the
[LineageOS build guide](https://wiki.lineageos.org/devices/Spacewar/build/) for host packages,
`repo` and `git-lfs`, which the vendor tree requires).

On a minimal or cloud Ubuntu image, also install AOSP's
[required packages](https://source.android.com/docs/setup/start/requirements). The LineageOS
list assumes desktop Ubuntu, where `unzip` and `fontconfig` come preinstalled, and without
`unzip` the build fails about half an hour into the compile. `build.sh` checks for it up front.

**Own machine:**

```bash
mkdir -p ~/android/lineage && cd ~/android/lineage
git clone -b lineage-24.0 https://github.com/Mu0810/local_manifests_Tetris /tmp/tetris-manifest
bash /tmp/tetris-manifest/build.sh
```

**crave.io devspace** (create a LineageOS 24 clone first, then from its root):

```bash
crave run --no-patch -- "rm -rf .repo/local_manifests && \
  git clone -b lineage-24.0 https://github.com/Mu0810/local_manifests_Tetris .repo/local_manifests && \
  bash .repo/local_manifests/build.sh"
```

Output lands in `out/target/product/Tetris/`: `lineage-24.0-*-UNOFFICIAL-Tetris.zip`
plus `boot.img`, `dtbo.img` and `vendor_boot.img`. The device has no recovery partition;
LineageOS Recovery lives in `vendor_boot`.

## What `apply-patches.sh` changes

**Device tree retarget.** The `xylobium` branch builds BlissROMs. The script generates
`lineage_Tetris.mk` from upstream's `bliss_Tetris.mk` on every run, so firmware bumps
upstream (build fingerprint, etc.) carry over. It also repoints two `BoardConfig.mk`
includes to their LineageOS equivalents (`BoardConfigReservedSize.mk`,
`libion/sepolicy.mk`). Before committing, it checks that no `vendor/bliss` or
`device/bliss` path remains anywhere in the tree. If one does, it rolls the tree back and
stops, so a renamed upstream file fails in seconds instead of hours into `m bacon`.

**Patches** (each `git am`'d into its project, skipped if already applied):

- `packages/apps/Aperture`: 60 FPS video recording on MediaTek (2 patches).

Every change is a local commit, so `repo sync` discards it cleanly and the next run of the
script re-applies it.

## Not applied, and why

**`pending/`: UDFPS (under-display fingerprint) fixes for MediaTek.** The device tree's
overlay turns these on (`config_udfpsMtkGhbmDimming`), but both patches were written for
LineageOS 23.x and **do not apply to 24.0**. Upstream has no Android 17 version yet.
Without them the build still compiles; the patch authors describe the symptom as a white
"flashbang" on the fingerprint prompt. They need rebasing before moving into `patches/`:

- `frameworks/base`: SystemUI MediaTek UDFPS dim-layer handling
  ([source](https://github.com/Nothing-2A/android_frameworks_base/commit/71955520858075bfeb8b52009151ba20401f27e3))
- `frameworks/native`: RenderEngine dither for MediaTek optical UDFPS
  ([source](https://github.com/Nothing-2A/android_frameworks_native/commit/7b7807349f7b66c61444e32e4a26b025932117d8))

**fenrir patched-LK support: deliberately excluded.** It only matters if you flashed a
bootloader patched with the [fenrir](https://github.com/R0rt1z2/fenrir) secure-boot exploit.
A stock unlocked bootloader does not need it.

**Kernel source.** The build uses the prebuilt kernel from `device/nothing/Tetris-kernel`,
so the kernel source repositories are not synced.

## Before flashing

- Unlocking the bootloader **wipes the phone**. Back up first.
- The zip also flashes low-level firmware (preloader, LK, TEE, modem) from Nothing OS 4.1
  (`Tetris_B4.1-260615`). Flashing it over **newer** firmware is a downgrade, the classic
  way to hard-brick a MediaTek phone. Check the phone's Nothing OS version first, and keep
  the matching stock fastboot package to hand from the
  [Nothing archive](https://github.com/quintenvandamme/nothing_archive).
- Play Integrity fails with an unlocked bootloader (Google Wallet, some banking apps).
- **Never re-lock the bootloader** while a custom ROM is installed.

## Credits

Device, vendor and kernel trees: the [CMF-Phone-1](https://github.com/CMF-Phone-1)
maintainers. Aperture patches: bengris32 and sreelekshman. UDFPS patches:
[Nothing-2A](https://github.com/Nothing-2A). Dolby: [swiitch-OFF-Lab](https://github.com/swiitch-OFF-Lab).
Built on [LineageOS](https://lineageos.org).
