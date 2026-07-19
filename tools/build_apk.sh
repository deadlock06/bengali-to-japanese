#!/usr/bin/env bash
# Bhasago — one-shot Android APK builder for a machine with NO Android SDK/JDK.
# Installs a local JDK 21 + Android cmdline-tools (no root, no Android Studio),
# then builds a release APK (signed with debug keys → directly sideloadable).
# Idempotent: re-running skips anything already downloaded. Safe to Ctrl-C and
# restart. Everything lands under ~/android-sdk and ~/jdk21 (nothing needs sudo).
#
#   bash tools/build_apk.sh
#
# Output: build/app/outputs/flutter-apk/app-release.apk
set -euo pipefail

FLUTTER_BIN="$HOME/flutter/bin"
SDK="$HOME/android-sdk"
JDK="$HOME/jdk21"
DL="$HOME/dl"
CMDTOOLS_ZIP="commandlinetools-linux-11076708_latest.zip"
export PATH="$FLUTTER_BIN:$PATH"
mkdir -p "$DL" "$SDK"

say(){ printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
die(){ printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ── single-instance lock ─────────────────────────────────────────────────────
# Running this script twice at once makes two curls write the SAME file and
# corrupts the download. flock guarantees only one run proceeds; a second run
# exits immediately with a clear message instead of colliding.
exec 9>"$HOME/.bhasago_build_apk.lock"
if ! flock -n 9; then
  die "Another build_apk.sh is already running (lock: ~/.bhasago_build_apk.lock).
     Let that one finish, or kill it first:  pkill -f build_apk.sh"
fi

# fetch URL DEST — atomic download: write to DEST.part, then move into place only
# on success, so a killed/duplicate download never leaves a corrupt final file.
fetch(){
  local url="$1" dest="$2"
  [ -s "$dest" ] && { echo "  (already have $(basename "$dest"))"; return 0; }
  curl -fL --retry 3 --retry-delay 2 -C - -o "$dest.part" "$url" \
    || die "download failed: $url"
  mv -f "$dest.part" "$dest"
}

# ── 1. Local JDK 21 (Gradle 9.1 / AGP 9.0.1 need JDK 17+) ─────────────────────
if [ ! -x "$JDK/bin/javac" ]; then
  say "Downloading JDK 21 (Temurin, ~190 MB)…"
  fetch "https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jdk/hotspot/normal/eclipse" \
    "$DL/jdk21.tar.gz"
  tar -tzf "$DL/jdk21.tar.gz" >/dev/null 2>&1 || die "JDK archive corrupt — delete ~/dl/jdk21.tar.gz and re-run."
  say "Extracting JDK…"
  rm -rf "$JDK" && mkdir -p "$JDK"
  tar -xzf "$DL/jdk21.tar.gz" -C "$JDK" --strip-components=1
fi
export JAVA_HOME="$JDK"
export PATH="$JAVA_HOME/bin:$PATH"
java -version

# ── 2. Android command-line tools → sdkmanager ───────────────────────────────
if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
  say "Downloading Android command-line tools (~120 MB)…"
  fetch "https://dl.google.com/android/repository/$CMDTOOLS_ZIP" "$DL/$CMDTOOLS_ZIP"
  unzip -tq "$DL/$CMDTOOLS_ZIP" >/dev/null 2>&1 \
    || die "cmdline-tools zip corrupt — delete ~/dl/$CMDTOOLS_ZIP and re-run."
  say "Installing cmdline-tools…"
  rm -rf "$SDK/cmdline-tools/latest" "$SDK/cmdline-tools/cmdline-tools"
  mkdir -p "$SDK/cmdline-tools"
  unzip -q -o "$DL/$CMDTOOLS_ZIP" -d "$SDK/cmdline-tools"
  mv "$SDK/cmdline-tools/cmdline-tools" "$SDK/cmdline-tools/latest"
fi
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
SDKMGR="$SDK/cmdline-tools/latest/bin/sdkmanager"

# ── 3. Accept licenses + install SDK packages ────────────────────────────────
say "Accepting SDK licenses…"
yes | "$SDKMGR" --sdk_root="$SDK" --licenses >/dev/null || true
say "Installing platform-tools + platforms + build-tools (~1 GB, one-time)…"
"$SDKMGR" --sdk_root="$SDK" \
  "platform-tools" \
  "platforms;android-36" "platforms;android-35" \
  "build-tools;36.0.0" "build-tools;35.0.0"

# ── 4. Point Flutter at this SDK + JDK ───────────────────────────────────────
say "Configuring Flutter toolchain…"
flutter config --android-sdk "$SDK" >/dev/null 9>&-
flutter config --jdk-dir "$JDK"     >/dev/null 9>&-
yes | flutter doctor --android-licenses >/dev/null 2>&1 9>&- || true
flutter doctor -v 9>&- 2>&1 | sed -n '/Android toolchain/,/^\[/p' | head -12

# ── 5. Build the APK ─────────────────────────────────────────────────────────
say "Building release APK (first build downloads Gradle 9.1 — be patient)…"
cd "$(dirname "$0")/.."
# 9>&- : don't leak the lock fd into flutter's long-lived children (adb daemon
# inherited it once and held the lock after the build finished).
flutter build apk --release --no-tree-shake-icons 9>&-

APK="build/app/outputs/flutter-apk/app-release.apk"
say "DONE ✅  →  $(pwd)/$APK"
ls -lh "$APK"
echo
echo "Copy that .apk to your phone (USB / Google Drive / Telegram-to-self), open it,"
echo "and allow 'Install unknown apps' when prompted. It's signed with debug keys,"
echo "which is fine for sideloading (not for Play Store)."
