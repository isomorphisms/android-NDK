#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
: "${ANDROID_SDK_ROOT:?ANDROID_SDK_ROOT is required}"
: "${ANDROID_TEST_KEYSTORE:?ANDROID_TEST_KEYSTORE is required}"

ndk_version=${ANDROID_NDK_VERSION:-26.3.11579264}
ndk="$ANDROID_SDK_ROOT/ndk/$ndk_version"
toolchain="$ndk/toolchains/llvm/prebuilt/linux-x86_64"
cc="$toolchain/bin/armv7a-linux-androideabi21-clang"
[[ -x "$cc" ]] || { echo "missing NDK compiler: $cc" >&2; exit 1; }

work=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/android-ndk-packager-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

"$cc" -shared -fPIC \
    "$repo_root/apk/tests/fixtures/native_activity.c" \
    -Wl,-soname,libfixture.so \
    -Wl,-u,ANativeActivity_onCreate \
    -landroid -llog \
    -o "$work/libfixture.so"

export ANDROID_PACKAGE_ID=org.isomorphisms.androidndk.fixture
export ANDROID_VERSION_CODE=1
export ANDROID_VERSION_NAME=1-test
export ANDROID_MIN_SDK=21
export ANDROID_TARGET_SDK=34
export ANDROID_KEYSTORE="$ANDROID_TEST_KEYSTORE"
export ANDROID_KEYSTORE_TYPE=PKCS12
export ANDROID_KEY_ALIAS=wegert-debug
export ANDROID_STORE_PASSWORD=wegert-debug
export ANDROID_KEY_PASSWORD=wegert-debug
export ANDROID_EXPECTED_CERT_SHA256=de9b1d47c5a65e6d46a204b79dd9ee566b9d3c9832ba81ebc4213d3392e92ff9
export ANDROID_SOURCE_COMMIT="${GITHUB_SHA:-fixture}"

"$repo_root/apk/build-nativeactivity-apk.sh" \
    "$repo_root/apk/tests/fixtures/AndroidManifest.xml" \
    "$work/libfixture.so" \
    armeabi-v7a \
    "$work/fixture.apk"

test -s "$work/fixture.apk"
test -s "$work/fixture.receipt.tsv"
grep -Fq $'package\torg.isomorphisms.androidndk.fixture' "$work/fixture.receipt.tsv"
grep -Fq $'signer_cert_sha256\tde9b1d47c5a65e6d46a204b79dd9ee566b9d3c9832ba81ebc4213d3392e92ff9' "$work/fixture.receipt.tsv"

if ANDROID_EXPECTED_CERT_SHA256=0000000000000000000000000000000000000000000000000000000000000000 \
    "$repo_root/apk/build-nativeactivity-apk.sh" \
      "$repo_root/apk/tests/fixtures/AndroidManifest.xml" \
      "$work/libfixture.so" \
      armeabi-v7a \
      "$work/wrong.apk" >"$work/wrong.log" 2>&1
then
    echo "wrong certificate unexpectedly passed" >&2
    exit 1
fi
grep -Fq "keystore certificate changed" "$work/wrong.log"
test ! -e "$work/wrong.apk"

if env -u ANDROID_KEYSTORE \
    "$repo_root/apk/build-nativeactivity-apk.sh" \
      "$repo_root/apk/tests/fixtures/AndroidManifest.xml" \
      "$work/libfixture.so" \
      armeabi-v7a \
      "$work/missing.apk" >"$work/missing.log" 2>&1
then
    echo "missing signer unexpectedly passed" >&2
    exit 1
fi
grep -Fq "required value is unset: ANDROID_KEYSTORE" "$work/missing.log"
test ! -e "$work/missing.apk"

printf 'android-NDK NativeActivity packager tests: PASS\n'
