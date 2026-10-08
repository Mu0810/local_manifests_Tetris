#!/usr/bin/env bash
#
# Build LineageOS 24.0 for the CMF Phone 1 (Tetris), end to end.
#
# Run from the directory that holds (or will hold) the LineageOS source:
#
#   mkdir -p ~/android/lineage && cd ~/android/lineage
#   bash /path/to/local_manifests_Tetris/build.sh
#
# On a crave.io devspace the tree is already initialised; see README.md.
# Needs: x86_64 Linux, repo, git-lfs, and the LineageOS host packages.
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH="lineage-24.0"
JOBS="${JOBS:-$(nproc)}"

[[ "$(uname -s)-$(uname -m)" == "Linux-x86_64" ]] \
    || { echo "build: Android builds need x86_64 Linux (this is $(uname -s) $(uname -m))" >&2; exit 1; }

# Host tools the build shells out to. The LineageOS package list assumes desktop
# Ubuntu, where unzip comes preinstalled; minimal and cloud images lack it, and the
# build then fails about 30 minutes into the compile. Fail here instead.
missing=()
for t in git git-lfs repo python3 zip unzip; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
done
if (( ${#missing[@]} )); then
    echo "build: missing host tools: ${missing[*]}" >&2
    echo "build: install the LineageOS host packages plus AOSP's (adds unzip, fontconfig); see README.md" >&2
    exit 1
fi

if [[ ! -d .repo ]]; then
    echo "build: initialising LineageOS $BRANCH in $PWD"
    repo init -u https://github.com/LineageOS/android.git -b "$BRANCH" --git-lfs --no-clone-bundle
fi

# Install the local manifest, unless this checkout already *is* .repo/local_manifests.
if [[ "$HERE" != "$(cd .repo && pwd)/local_manifests" ]]; then
    mkdir -p .repo/local_manifests
    cp "$HERE/tetris.xml" .repo/local_manifests/tetris.xml
fi

if [[ -x /opt/crave/resync.sh ]]; then
    /opt/crave/resync.sh                  # crave.io devspaces ship their own sync wrapper
else
    repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags
fi

bash "$HERE/apply-patches.sh"

set +u                                    # envsetup.sh is not nounset-safe
# shellcheck disable=SC1091
source build/envsetup.sh
breakfast Tetris
m bacon

echo "build: done. Outputs in out/target/product/Tetris/:"
ls -1 out/target/product/Tetris/lineage-*.zip out/target/product/Tetris/{boot,dtbo,vendor_boot}.img || true
