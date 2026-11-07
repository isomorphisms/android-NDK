#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
output=${1:-"$repo_root/build/exec/reddit/libreddit_cli.so"}
api=${ANDROID_API:-24}
abi=${ANDROID_ABI:-x86_64}

case "$abi" in
  x86_64) target=x86_64-linux-android; ick_target=x86_64-linux-gnu; header_target=x86_64-linux-android; ick_flags=(-march=x86-64-v2 -mno-avx -mno-movbe) ;;
  x86) target=i686-linux-android; ick_target=i686-linux-gnu; header_target=i686-linux-android; ick_flags=(-march=i686 -mssse3 -mfpmath=sse -mstackrealign) ;;
  arm64-v8a) target=aarch64-linux-android; ick_target=aarch64-linux-gnu; header_target=aarch64-linux-android; ick_flags=(-ffixed-x18) ;;
  armeabi-v7a) target=armv7a-linux-androideabi; ick_target=arm-linux-gnueabi; header_target=arm-linux-androideabi; ick_flags=(-march=armv7-a -mthumb -mfpu=neon -mfloat-abi=softfp) ;;
  *)
    echo "unsupported Android ABI: $abi" >&2
    exit 1
    ;;
esac

ick=${ICK_CC:-${ICK_ROOT:+$ICK_ROOT/bin/${ick_target}-gcc}}
[[ -n $ick && -x $ick ]] || {
  printf 'ICK compiler is required; set ICK_CC or ICK_ROOT for %s.\n' "$ick_target" >&2
  exit 1
}
[[ $("$ick" -dumpmachine) == "$ick_target" ]] || {
  printf 'ICK compiler does not target %s.\n' "$ick_target" >&2
  exit 1
}
builtin_include=$("$ick" -print-file-name=include)
[[ -d $builtin_include ]] || {
  printf 'ICK builtin headers are missing: %s\n' "$builtin_include" >&2
  exit 1
}

ndk=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}
if [[ -z $ndk ]]; then
  android_home=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
  [[ -n $android_home ]] || {
    echo 'ANDROID_HOME/ANDROID_SDK_ROOT is required' >&2
    exit 1
  }
  ndk=$(find "$android_home/ndk" -mindepth 1 -maxdepth 1 -type d 2>/dev/null |
    sort -V | tail -n 1)
fi
[[ -n $ndk && -d $ndk ]] || {
  echo 'Android NDK not found' >&2
  exit 1
}

ndk_bin="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
clang="$ndk_bin/${target}${api}-clang"
readelf="$ndk_bin/llvm-readelf"
[[ -x $clang ]] || {
  echo "Android $abi clang not found: $clang" >&2
  exit 1
}
[[ -x $readelf ]] || {
  echo "Android NDK llvm-readelf not found: $readelf" >&2
  exit 1
}

mkdir -p "$(dirname -- "$output")"
sysroot="$ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
"$ick" "${ick_flags[@]}" -std=c17 -fPIC -O2 -Wall -Wextra -Werror \
  -nostdinc -isystem "$builtin_include" --sysroot="$sysroot" \
  -isystem "$sysroot/usr/include" -isystem "$sysroot/usr/include/$header_target" \
  -D__ANDROID__ -D__ANDROID_API__="$api" -D__ANDROID_MIN_SDK_VERSION__="$api" \
  -DBIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD \
  -S "$repo_root/tests/dex/reddit/reddit_cli.c" -o "$output.s"
"$clang" "${ick_flags[@]}" -c "$output.s" -o "$output.o"
"$clang" -shared -fPIC -O2 -Wall -Wextra -Werror \
  -Wl,--no-undefined -Wl,-soname,libreddit_cli.so \
  "$output.o" -o "$output"

# Finish readelf before grep -q can close a pipe and make LLVM exit 74.
# Keep readelf failure fatal even when its partial output contains a match.
symbols=$("$readelf" -Ws "$output")
grep -Fq 'Java_org_isomorphisms_reddit_RedditCli_run' <<<"$symbols"
printf 'Reddit JNI ABI          %s\n' "$abi"
printf 'Reddit JNI API          %s\n' "$api"
printf 'Reddit JNI C frontend   %s\n' "$ick"
printf 'NDK assembly/link       %s\n' "$clang"
