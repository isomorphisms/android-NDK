#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
    printf 'android-NDK APK build failed: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'usage: %s MANIFEST NATIVE_LIBRARY ABI OUTPUT_APK\n' "$0" >&2
    exit 2
}

[[ $# -eq 4 ]] || usage
manifest=$1
native_library=$2
abi=$3
output=$4

case "$abi" in
    armeabi-v7a|arm64-v8a|x86|x86_64) ;;
    *) fail "unsupported Android ABI: $abi" ;;
esac

require_value() {
    local name=$1
    [[ -n ${!name:-} ]] || fail "required value is unset: $name"
}

for name in \
    ANDROID_PACKAGE_ID \
    ANDROID_VERSION_CODE \
    ANDROID_VERSION_NAME \
    ANDROID_MIN_SDK \
    ANDROID_TARGET_SDK \
    ANDROID_KEYSTORE \
    ANDROID_KEYSTORE_TYPE \
    ANDROID_KEY_ALIAS \
    ANDROID_STORE_PASSWORD \
    ANDROID_KEY_PASSWORD \
    ANDROID_EXPECTED_CERT_SHA256
do
    require_value "$name"
done

[[ -f "$manifest" ]] || fail "missing manifest: $manifest"
[[ -f "$native_library" ]] || fail "missing native library: $native_library"
[[ "$ANDROID_VERSION_CODE" =~ ^[0-9]+$ ]] || fail "ANDROID_VERSION_CODE must be numeric"
[[ "$ANDROID_MIN_SDK" =~ ^[0-9]+$ ]] || fail "ANDROID_MIN_SDK must be numeric"
[[ "$ANDROID_TARGET_SDK" =~ ^[0-9]+$ ]] || fail "ANDROID_TARGET_SDK must be numeric"
[[ "$ANDROID_PACKAGE_ID" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$ ]] ||
    fail "invalid package id: $ANDROID_PACKAGE_ID"

android_home=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
[[ -n "$android_home" ]] || fail "ANDROID_HOME/ANDROID_SDK_ROOT is required"

build_tools=${ANDROID_BUILD_TOOLS:-}
if [[ -z "$build_tools" ]]; then
    build_tools=$(
        find "$android_home/build-tools" -mindepth 1 -maxdepth 1 -type d |
            sort -V |
            tail -n 1
    )
fi

aapt2="$build_tools/aapt2"
zipalign="$build_tools/zipalign"
apksigner="$build_tools/apksigner"
android_jar="$android_home/platforms/android-$ANDROID_TARGET_SDK/android.jar"

for required in "$aapt2" "$zipalign" "$apksigner" "$android_jar"; do
    [[ -e "$required" ]] || fail "missing Android packaging input: $required"
done
command -v keytool >/dev/null 2>&1 || fail "keytool is required"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"
command -v unzip >/dev/null 2>&1 || fail "unzip is required"
command -v zip >/dev/null 2>&1 || fail "zip is required"

expected_cert=$(
    printf '%s' "$ANDROID_EXPECTED_CERT_SHA256" |
        tr '[:upper:]' '[:lower:]' |
        tr -d ':[:space:]'
)
[[ "$expected_cert" =~ ^[0-9a-f]{64}$ ]] ||
    fail "ANDROID_EXPECTED_CERT_SHA256 is not a SHA-256 certificate digest"
[[ -f "$ANDROID_KEYSTORE" ]] || fail "required keystore is missing: $ANDROID_KEYSTORE"

keystore_cert=$(
    keytool -exportcert \
        -keystore "$ANDROID_KEYSTORE" \
        -storetype "$ANDROID_KEYSTORE_TYPE" \
        -storepass "$ANDROID_STORE_PASSWORD" \
        -alias "$ANDROID_KEY_ALIAS" \
        2>/dev/null |
    sha256sum |
    awk '{print $1}'
)
[[ "$keystore_cert" == "$expected_cert" ]] ||
    fail "keystore certificate changed: expected $expected_cert got $keystore_cert"

output_dir=$(dirname -- "$output")
mkdir -p "$output_dir"
work=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/android-ndk-apk.XXXXXX")
trap 'rm -rf "$work"' EXIT

libname=$(basename -- "$native_library")
mkdir -p "$work/payload/lib/$abi"
cp "$native_library" "$work/payload/lib/$abi/$libname"

manifest_apk="$work/manifest.apk"
unaligned="$work/unaligned.apk"
aligned="$work/aligned.apk"
signed="$work/verified.apk"

# Application-specific icons, strings and other resources are supplied as a
# read-only input. An application without resources preserves the old route.
resources=()
if [[ -n ${ANDROID_RES_DIR:-} ]]; then
    [[ -d "$ANDROID_RES_DIR" ]] ||
        fail "ANDROID_RES_DIR is not a directory: $ANDROID_RES_DIR"
    "$aapt2" compile --dir "$ANDROID_RES_DIR" -o "$work/resources.zip"
    resources+=("$work/resources.zip")
fi

"$aapt2" link \
    -I "$android_jar" \
    --manifest "$manifest" \
    --rename-manifest-package "$ANDROID_PACKAGE_ID" \
    --version-code "$ANDROID_VERSION_CODE" \
    --version-name "$ANDROID_VERSION_NAME" \
    --min-sdk-version "$ANDROID_MIN_SDK" \
    --target-sdk-version "$ANDROID_TARGET_SDK" \
    -o "$manifest_apk" \
    "${resources[@]}"

cp "$manifest_apk" "$unaligned"
(
    cd "$work/payload"
    zip -q -u "$unaligned" "lib/$abi/$libname"
    if [[ -n ${ANDROID_ASSET_DIR:-} ]]; then
        [[ -d "$ANDROID_ASSET_DIR" ]] || fail "ANDROID_ASSET_DIR is not a directory: $ANDROID_ASSET_DIR"
        mkdir -p assets
        cp -R "$ANDROID_ASSET_DIR"/. assets/
        zip -q -u -r "$unaligned" assets
    fi
)

"$zipalign" -f 4 "$unaligned" "$aligned"

# Publish only once every finished-APK check passes. A failed candidate never
# replaces a previously verified output and never leaves a new unsigned APK.
"$apksigner" sign \
    --ks "$ANDROID_KEYSTORE" \
    --ks-type "$ANDROID_KEYSTORE_TYPE" \
    --ks-pass "pass:$ANDROID_STORE_PASSWORD" \
    --key-pass "pass:$ANDROID_KEY_PASSWORD" \
    --ks-key-alias "$ANDROID_KEY_ALIAS" \
    --out "$signed" \
    "$aligned"

cert_report=$("$apksigner" verify --verbose --print-certs "$signed" 2>&1)
printf '%s\n' "$cert_report"

apk_cert=$(
    printf '%s\n' "$cert_report" |
        sed -n 's/^.*certificate SHA-256 digest:[[:space:]]*//p' |
        tr '[:upper:]' '[:lower:]' |
        tr -d ':[:space:]' |
        sort -u
)
[[ -n "$apk_cert" && "$apk_cert" != *$'\n'* ]] ||
    fail "finished APK must contain exactly one signer certificate"
[[ "$apk_cert" == "$expected_cert" ]] ||
    fail "finished APK signer changed: expected $expected_cert got $apk_cert"

badging=$("$aapt2" dump badging "$signed")
observed_package=$(
    printf '%s\n' "$badging" |
        sed -n "s/^package: name='\([^']*\)'.*/\1/p" |
        head -n 1
)
observed_version_code=$(
    printf '%s\n' "$badging" |
        sed -n "s/^package: .*versionCode='\([^']*\)'.*/\1/p" |
        head -n 1
)
observed_activity=$(
    printf '%s\n' "$badging" |
        sed -n "s/^launchable-activity: name='\([^']*\)'.*/\1/p" |
        head -n 1
)
observed_label=$(
    printf '%s\n' "$badging" |
        sed -n -e "s/^application-label:'\(.*\)'$/\1/p" \
               -e "s/^application: label='\([^']*\)'.*/\1/p" |
        head -n 1
)

[[ "$observed_package" == "$ANDROID_PACKAGE_ID" ]] ||
    fail "finished APK package changed: expected $ANDROID_PACKAGE_ID got ${observed_package:-missing}"
[[ "$observed_version_code" == "$ANDROID_VERSION_CODE" ]] ||
    fail "finished APK versionCode changed: expected $ANDROID_VERSION_CODE got ${observed_version_code:-missing}"
[[ "$observed_activity" == "android.app.NativeActivity" ]] ||
    fail "finished APK launcher is not android.app.NativeActivity: ${observed_activity:-missing}"
if [[ -n ${ANDROID_EXPECTED_LABEL:-} ]]; then
    if [[ "$observed_label" != "$ANDROID_EXPECTED_LABEL" ]]; then
        printf '%s\n' "$badging" >&2
        fail "finished APK launcher label changed: expected $ANDROID_EXPECTED_LABEL got ${observed_label:-missing}"
    fi
fi

contents="$work/contents.txt"
unzip -l "$signed" > "$contents"
grep -Eq "[[:space:]]lib/$abi/$libname$" "$contents" ||
    fail "finished APK is missing lib/$abi/$libname"
if [[ ${ANDROID_REQUIRE_NO_DEX:-1} == 1 ]] &&
   grep -Eq '[[:space:]]classes[0-9]*\.dex$' "$contents"; then
    fail "finished NativeActivity APK unexpectedly contains DEX"
fi

apk_sha=$(sha256sum "$signed" | awk '{print $1}')
manifest_sha=$(sha256sum "$manifest" | awk '{print $1}')
native_sha=$(sha256sum "$native_library" | awk '{print $1}')
receipt="${output%.apk}.receipt.tsv"
mv -f "$signed" "$output"

{
    printf 'schema\tandroid-ndk-nativeactivity-apk-v1\n'
    printf 'package\t%s\n' "$observed_package"
    printf 'version_code\t%s\n' "$observed_version_code"
    printf 'version_name\t%s\n' "$ANDROID_VERSION_NAME"
    printf 'launcher_label\t%s\n' "$observed_label"
    printf 'abi\t%s\n' "$abi"
    printf 'native_library\t%s\n' "$libname"
    printf 'native_sha256\t%s\n' "$native_sha"
    printf 'manifest_sha256\t%s\n' "$manifest_sha"
    printf 'apk_sha256\t%s\n' "$apk_sha"
    printf 'signer_cert_sha256\t%s\n' "$apk_cert"
    printf 'source_commit\t%s\n' "${ANDROID_SOURCE_COMMIT:-unknown}"
} > "$receipt"

printf 'ANDROID_NDK_APK\tPASS\n'
printf 'PACKAGE\t%s\n' "$observed_package"
printf 'VERSION_CODE\t%s\n' "$observed_version_code"
printf 'ABI\t%s\n' "$abi"
printf 'APK_SHA256\t%s\n' "$apk_sha"
printf 'SIGNER_SHA256\t%s\n' "$apk_cert"
printf 'RECEIPT\t%s\n' "$receipt"
