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
export ANDROID_EXPECTED_LABEL="android-NDK fixture"

bash "$repo_root/apk/build-nativeactivity-apk.sh" \
    "$repo_root/apk/tests/fixtures/AndroidManifest.xml" \
    "$work/libfixture.so" \
    armeabi-v7a \
    "$work/fixture.apk"

test -s "$work/fixture.apk"
test -s "$work/fixture.receipt.tsv"
grep -Fq $'launcher_label\tandroid-NDK fixture' "$work/fixture.receipt.tsv"
grep -Fq $'package\torg.isomorphisms.androidndk.fixture' "$work/fixture.receipt.tsv"
grep -Fq $'signer_cert_sha256\tde9b1d47c5a65e6d46a204b79dd9ee566b9d3c9832ba81ebc4213d3392e92ff9' "$work/fixture.receipt.tsv"

# A truncated copy into publication staging must never replace a previously
# verified APK (or its receipt). This simulates an interrupted copy after the
# signed candidate was verified but before its destination-filesystem rename.
cp "$work/fixture.apk" "$work/previous.apk"
cp "$work/fixture.receipt.tsv" "$work/previous.receipt.tsv"
mkdir -p "$work/fault-bin"
cat > "$work/fault-bin/cp" <<'EOF'
#!/usr/bin/env bash
# The packager uses "cp -- SOURCE DEST"; keep the original argv for real cp.
if [[ ${1:-} == -- ]]; then
    source=${2:-}
    destination=${3:-}
else
    source=${1:-}
    destination=${2:-}
fi
if [[ "$source" == */verified.apk && "$destination" == */.android-ndk-publish.*/artifact.apk ]]; then
    printf 'truncated candidate' > "$destination"
    exit 0
fi
exec /bin/cp "$@"
EOF
chmod +x "$work/fault-bin/cp"
if PATH="$work/fault-bin:$PATH" \
    bash "$repo_root/apk/build-nativeactivity-apk.sh" \
      "$repo_root/apk/tests/fixtures/AndroidManifest.xml" \
      "$work/libfixture.so" armeabi-v7a \
      "$work/fixture.apk" >"$work/interrupted-publication.log" 2>&1
then
    fail "a truncated publication copy unexpectedly passed"
fi
grep -Fq 'publication staging changed signed APK content' "$work/interrupted-publication.log"
cmp "$work/fixture.apk" "$work/previous.apk" || fail "previous verified APK changed"
cmp "$work/fixture.receipt.tsv" "$work/previous.receipt.tsv" || fail "previous receipt changed"
if find "$work" -mindepth 1 -maxdepth 1 -type d -name '.android-ndk-publish.*' | grep -q .; then
    fail "failed publication left its staging directory"
fi


# The same signed app with a changed expected name must fail.
if ANDROID_EXPECTED_LABEL='Wegert' \
    bash "$repo_root/apk/build-nativeactivity-apk.sh" \
      "$repo_root/apk/tests/fixtures/AndroidManifest.xml" \
      "$work/libfixture.so" armeabi-v7a \
      "$work/wrong-name.apk" >"$work/wrong-name.log" 2>&1
then
    echo "launcher identity drift unexpectedly passed" >&2
    exit 1
fi
grep -Fq 'finished APK launcher label changed' "$work/wrong-name.log"
test ! -e "$work/wrong-name.apk"

# An activity-level label may override the correct application-level label.
sed 's/<activity/<activity android:label="Wrong Activity Name"/' \
    "$repo_root/apk/tests/fixtures/AndroidManifest.xml" > "$work/activity-name.xml"
if bash "$repo_root/apk/build-nativeactivity-apk.sh" \
      "$work/activity-name.xml" "$work/libfixture.so" armeabi-v7a \
      "$work/wrong-activity-name.apk" >"$work/wrong-activity-name.log" 2>&1
then
    echo "activity launcher name override unexpectedly passed" >&2
    exit 1
fi
grep -Fq 'finished APK launcher label changed' "$work/wrong-activity-name.log"
test ! -e "$work/wrong-activity-name.apk"

# Verify packaging can compile application-owned resources, not only bare manifests.
mkdir -p "$work/res/values"
printf '%s\n' '<resources><string name="app_name">android-NDK fixture</string></resources>' \
    > "$work/res/values/strings.xml"
sed 's/android:label="android-NDK fixture"/android:label="@string\/app_name"/' \
    "$repo_root/apk/tests/fixtures/AndroidManifest.xml" > "$work/resource-manifest.xml"
ANDROID_RES_DIR="$work/res" \
    bash "$repo_root/apk/build-nativeactivity-apk.sh" \
      "$work/resource-manifest.xml" "$work/libfixture.so" armeabi-v7a \
      "$work/with-resources.apk" > "$work/resource-build.log"
unzip -Z1 "$work/with-resources.apk" | grep -Fxq resources.arsc
test -s "$work/with-resources.receipt.tsv"

if ANDROID_EXPECTED_CERT_SHA256=0000000000000000000000000000000000000000000000000000000000000000 \
    bash "$repo_root/apk/build-nativeactivity-apk.sh" \
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
    bash "$repo_root/apk/build-nativeactivity-apk.sh" \
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
