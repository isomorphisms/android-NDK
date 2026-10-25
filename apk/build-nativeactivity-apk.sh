#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
    printf 'android-NDK APK build failed: %s\n' "$*" >&2
    exit 1
}

require_plain_tsv_value() {
    local name=$1
    local value=$2
    [[ "$value" != *$'\t'* && "$value" != *$'\n'* && "$value" != *$'\r'* ]] ||
        fail "$name contains a tab or newline"
}

tree_closure() {
    local root=$1
    local listing=$2
    local path relative digest

    : > "$listing"
    [[ -n "$root" ]] || {
        sha256sum "$listing" | awk '{print $1}'
        return
    }
    [[ -d "$root" ]] || fail "input tree is not a directory: $root"
    while IFS= read -r -d '' path; do
        relative=${path#"$root"/}
        require_plain_tsv_value "input path" "$relative"
        if [[ -d "$path" && ! -L "$path" ]]; then
            printf 'directory\t%s\n' "$relative" >> "$listing"
        elif [[ -f "$path" && ! -L "$path" ]]; then
            digest=$(sha256sum "$path" | awk '{print $1}')
            printf 'file\t%s\t%s\n' "$relative" "$digest" >> "$listing"
        else
            fail "input tree contains unsupported entry: $path"
        fi
    done < <(find "$root" -mindepth 1 -print0 | LC_ALL=C sort -z)
    sha256sum "$listing" | awk '{print $1}'
}

stage_normalized_tree() {
    local root=$1
    local destination=$2
    local listing=$3
    local kind relative digest source target

    mkdir -p "$destination"
    while IFS=$'\t' read -r kind relative digest; do
        [[ -n "$kind" ]] || continue
        source="$root/$relative"
        target="$destination/$relative"
        case "$kind" in
            directory)
                mkdir -p "$target"
                chmod 0755 "$target"
                ;;
            file)
                mkdir -p "$(dirname -- "$target")"
                cp -- "$source" "$target"
                chmod 0644 "$target"
                ;;
            *) fail "unsupported closure entry: $kind" ;;
        esac
        touch -h -d "@$SOURCE_DATE_EPOCH" "$target"
    done < "$listing"
    find "$destination" -type d -exec chmod 0755 {} +
    find "$destination" -type d -exec touch -d "@$SOURCE_DATE_EPOCH" {} +
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
signing_options=()
zip_options=()
source_date_epoch=unset
approved_source_date_epoch=unset
timestamp_normalization=unchanged
mode_normalization=unchanged
entry_order=tool-default
zip_metadata=tool-default
if [[ -n ${SOURCE_DATE_EPOCH:-} ]]; then
    [[ "$SOURCE_DATE_EPOCH" =~ ^[0-9]{1,10}$ ]] || fail "SOURCE_DATE_EPOCH must be an integer"
    (( SOURCE_DATE_EPOCH >= 315532800 )) || fail "SOURCE_DATE_EPOCH predates ZIP timestamps"
    (( ANDROID_MIN_SDK >= 24 )) || fail "reproducible signing requires API 24 or newer (APK signature v2)"
    [[ -n ${ANDROID_EXPECTED_SOURCE_DATE_EPOCH:-} ]] ||
        fail "ANDROID_EXPECTED_SOURCE_DATE_EPOCH is required with SOURCE_DATE_EPOCH"
    [[ "$ANDROID_EXPECTED_SOURCE_DATE_EPOCH" =~ ^[0-9]{1,10}$ ]] ||
        fail "ANDROID_EXPECTED_SOURCE_DATE_EPOCH must be an integer"
    [[ "$SOURCE_DATE_EPOCH" == "$ANDROID_EXPECTED_SOURCE_DATE_EPOCH" ]] ||
        fail "SOURCE_DATE_EPOCH does not match approved epoch: expected $ANDROID_EXPECTED_SOURCE_DATE_EPOCH got $SOURCE_DATE_EPOCH"
    [[ ${ANDROID_SOURCE_COMMIT:-} =~ ^[0-9a-fA-F]{40}([0-9a-fA-F]{24})?$ ]] ||
        fail "ANDROID_SOURCE_COMMIT must be an exact 40- or 64-hex revision in reproducible mode"
    export TZ=UTC
    signing_options=(
        --v1-signing-enabled false
        --v2-signing-enabled true
        --v3-signing-enabled false
        --v4-signing-enabled false
    )
    zip_options=(-X)
    source_date_epoch=$SOURCE_DATE_EPOCH
    approved_source_date_epoch=$ANDROID_EXPECTED_SOURCE_DATE_EPOCH
    timestamp_normalization=source-date-epoch-utc
    mode_normalization=files-0644-directories-0755
    entry_order=lc-all-c-relative-path
    zip_metadata=strip-uid-gid-extra
elif [[ -n ${ANDROID_EXPECTED_SOURCE_DATE_EPOCH:-} ]]; then
    fail "ANDROID_EXPECTED_SOURCE_DATE_EPOCH requires SOURCE_DATE_EPOCH"
fi
[[ "$ANDROID_PACKAGE_ID" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$ ]] ||
    fail "invalid package id: $ANDROID_PACKAGE_ID"
expected_activity=${ANDROID_ACTIVITY_CLASS:-android.app.NativeActivity}
[[ "$expected_activity" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$ ]] ||
    fail "invalid declared NativeActivity class: $expected_activity"
if [[ "$expected_activity" != android.app.NativeActivity ]]; then
    [[ -n ${ANDROID_DEX_FILE:-} ]] || fail "a declared NativeActivity subclass requires a direct DEX input"
    [[ -f ${ANDROID_BAKSMALI_JAR:-} ]] || fail "a declared NativeActivity subclass requires pinned baksmali"
    oracle_sha=$(sha256sum "$ANDROID_BAKSMALI_JAR" | awk '{print $1}')
    [[ "$oracle_sha" == 37ae4a41a8886e15c20b8362fa4250f96bbdb55e1a608199ad8b5dff068b588f ]] ||
        fail "NativeActivity subclass disassembler digest changed"
fi

for value_name in \
    ANDROID_PACKAGE_ID ANDROID_VERSION_CODE ANDROID_VERSION_NAME \
    ANDROID_MIN_SDK ANDROID_TARGET_SDK ANDROID_EXPECTED_LABEL \
    ANDROID_SOURCE_COMMIT SOURCE_DATE_EPOCH ANDROID_EXPECTED_SOURCE_DATE_EPOCH
do
    require_plain_tsv_value "$value_name" "${!value_name:-}"
done

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
apksigner_jar="$build_tools/lib/apksigner.jar"
android_jar="$android_home/platforms/android-$ANDROID_TARGET_SDK/android.jar"

for required in "$aapt2" "$zipalign" "$apksigner" "$apksigner_jar" "$android_jar"; do
    [[ -e "$required" ]] || fail "missing Android packaging input: $required"
done
command -v keytool >/dev/null 2>&1 || fail "keytool is required"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"
command -v unzip >/dev/null 2>&1 || fail "unzip is required"
command -v zip >/dev/null 2>&1 || fail "zip is required"
zip_tool=$(command -v zip)

packager_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
schema_file="$packager_dir/nativeactivity-receipt-v2.schema.tsv"
schema_id=android-ndk-nativeactivity-apk-v2
if [[ -n ${ANDROID_DEX_FILE:-} ]]; then
    schema_file="$packager_dir/nativeactivity-receipt-v3.schema.tsv"
    schema_id=android-ndk-nativeactivity-apk-v3
fi
verifier_file="$packager_dir/verify-nativeactivity-receipt.grease"
grease_runtime=${ANDROID_GREASE:-}
[[ -x "$grease_runtime" ]] || fail "ANDROID_GREASE must name the verified Grease runtime"
[[ -f "$schema_file" ]] || fail "missing receipt schema: $schema_file"
[[ -f "$verifier_file" ]] || fail "missing receipt verifier: $verifier_file"
packager_sha=$(sha256sum "$0" | awk '{print $1}')
schema_sha=$(sha256sum "$schema_file" | awk '{print $1}')
verifier_sha=$(sha256sum "$verifier_file" | awk '{print $1}')
aapt2_sha=$(sha256sum "$aapt2" | awk '{print $1}')
zipalign_sha=$(sha256sum "$zipalign" | awk '{print $1}')
apksigner_sha=$(sha256sum "$apksigner" | awk '{print $1}')
apksigner_jar_sha=$(sha256sum "$apksigner_jar" | awk '{print $1}')
android_jar_sha=$(sha256sum "$android_jar" | awk '{print $1}')
zip_sha=$(sha256sum "$zip_tool" | awk '{print $1}')

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
trap 'rm -rf "$work"; if [[ -n ${publish_stage:-} ]]; then rm -rf "$publish_stage"; fi' EXIT

libname=$(basename -- "$native_library")
mkdir -p "$work/payload/lib/$abi"
cp "$native_library" "$work/payload/lib/$abi/$libname"
if [[ -n ${ANDROID_DEX_FILE:-} ]]; then
    [[ -f "$ANDROID_DEX_FILE" ]] || fail "missing declared direct DEX input: $ANDROID_DEX_FILE"
    [[ ! -L "$ANDROID_DEX_FILE" ]] || fail "declared direct DEX input must not be a symlink"
    [[ ${ANDROID_REQUIRE_NO_DEX:-1} == 0 ]] ||
        fail "declared DEX input requires ANDROID_REQUIRE_NO_DEX=0"
    cp "$ANDROID_DEX_FILE" "$work/payload/classes.dex"
    if [[ -n ${SOURCE_DATE_EPOCH:-} ]]; then
        touch -d "@$SOURCE_DATE_EPOCH" "$work/payload/classes.dex"
        chmod 0644 "$work/payload/classes.dex"
    fi
fi
if [[ -n ${SOURCE_DATE_EPOCH:-} ]]; then
    touch -d "@$SOURCE_DATE_EPOCH" "$work/payload/lib/$abi/$libname"
    chmod 0644 "$work/payload/lib/$abi/$libname"
fi

manifest_apk="$work/manifest.apk"
unaligned="$work/unaligned.apk"
aligned="$work/aligned.apk"
signed="$work/verified.apk"
resource_listing="$work/resource-closure.tsv"
asset_listing="$work/asset-closure.tsv"
resource_root=${ANDROID_RES_DIR:-}
asset_root=${ANDROID_ASSET_DIR:-}
resource_closure_sha=$(tree_closure "$resource_root" "$resource_listing")
asset_closure_sha=$(tree_closure "$asset_root" "$asset_listing")

# Application-specific icons, strings and other resources are supplied as a
# read-only input. An application without resources preserves the old route.
resources=()
if [[ -n "$resource_root" ]]; then
    if [[ -n ${SOURCE_DATE_EPOCH:-} ]]; then
        normalized_resources="$work/normalized-resources"
        stage_normalized_tree "$resource_root" "$normalized_resources" "$resource_listing"
        resource_root=$normalized_resources
    fi
    "$aapt2" compile --dir "$resource_root" -o "$work/resources.zip"
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
    "$zip_tool" -q -u "${zip_options[@]}" "$unaligned" "lib/$abi/$libname"
    if [[ -n ${ANDROID_DEX_FILE:-} ]]; then
        "$zip_tool" -q -u "${zip_options[@]}" "$unaligned" classes.dex
    fi
    if [[ -n "$asset_root" ]]; then
        if [[ -n ${SOURCE_DATE_EPOCH:-} ]]; then
            stage_normalized_tree "$asset_root" assets "$asset_listing"
        else
            mkdir -p assets
            cp -R "$asset_root"/. assets/
        fi
        find assets -print0 | LC_ALL=C sort -z |
            tr '\0' '\n' |
            "$zip_tool" -q -u "${zip_options[@]}" "$unaligned" -@
    fi
)

unsigned_apk_sha=$(sha256sum "$unaligned" | awk '{print $1}')

"$zipalign" -f 4 "$unaligned" "$aligned"
aligned_apk_sha=$(sha256sum "$aligned" | awk '{print $1}')

# Publish only once every finished-APK check passes. A failed candidate never
# replaces a previously verified output and never leaves a new unsigned APK.
"$apksigner" sign \
    "${signing_options[@]}" \
    --ks "$ANDROID_KEYSTORE" \
    --ks-type "$ANDROID_KEYSTORE_TYPE" \
    --ks-pass "pass:$ANDROID_STORE_PASSWORD" \
    --key-pass "pass:$ANDROID_KEY_PASSWORD" \
    --ks-key-alias "$ANDROID_KEY_ALIAS" \
    --out "$signed" \
    "$aligned"

cert_report=$("$apksigner" verify --verbose --print-certs "$signed" 2>&1)
printf '%s\n' "$cert_report"

sig_v1=$(printf '%s\n' "$cert_report" |
    sed -n 's/^Verified using v1 scheme (JAR signing): //p' | head -n 1)
sig_v2=$(printf '%s\n' "$cert_report" |
    sed -n 's/^Verified using v2 scheme (APK Signature Scheme v2): //p' | head -n 1)
sig_v3=$(printf '%s\n' "$cert_report" |
    sed -n 's/^Verified using v3 scheme (APK Signature Scheme v3): //p' | head -n 1)
sig_v31=$(printf '%s\n' "$cert_report" |
    sed -n 's/^Verified using v3.1 scheme (APK Signature Scheme v3.1): //p' | head -n 1)
sig_v4=$(printf '%s\n' "$cert_report" |
    sed -n 's/^Verified using v4 scheme (APK Signature Scheme v4): //p' | head -n 1)
sig_v1=${sig_v1:-unreported}
sig_v2=${sig_v2:-unreported}
sig_v3=${sig_v3:-unreported}
sig_v31=${sig_v31:-unreported}
sig_v4=${sig_v4:-unreported}
signature_mode="v1-$sig_v1,v2-$sig_v2,v3-$sig_v3,v3.1-$sig_v31,v4-$sig_v4"
signature_policy=apksigner-default
if [[ -n ${SOURCE_DATE_EPOCH:-} ]]; then
    [[ "$sig_v1" == false && "$sig_v2" == true && "$sig_v3" == false ]] ||
        fail "reproducible signing mode changed: expected v1=false,v2=true,v3=false got $signature_mode"
    signature_policy=apk-signature-v2-only
fi

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
observed_launcher_label=$(
    printf '%s\n' "$badging" |
        sed -n "s/^launchable-activity:.* label='\([^']*\)'.*/\1/p" |
        head -n 1
)

[[ "$observed_package" == "$ANDROID_PACKAGE_ID" ]] ||
    fail "finished APK package changed: expected $ANDROID_PACKAGE_ID got ${observed_package:-missing}"
[[ "$observed_version_code" == "$ANDROID_VERSION_CODE" ]] ||
    fail "finished APK versionCode changed: expected $ANDROID_VERSION_CODE got ${observed_version_code:-missing}"
[[ "$observed_activity" == "$expected_activity" ]] ||
    fail "finished APK launcher changed: expected $expected_activity got ${observed_activity:-missing}"
if [[ -n ${ANDROID_EXPECTED_LABEL:-} ]]; then
    # aapt2 reports label='' for an activity that inherits the app label.
    # Only an explicit, nonempty activity label can override that default.
    if [[ "$observed_label" != "$ANDROID_EXPECTED_LABEL" ||
          ( -n "$observed_launcher_label" && "$observed_launcher_label" != "$ANDROID_EXPECTED_LABEL" ) ]]; then
        printf '%s\n' "$badging" >&2
        fail "finished APK launcher label changed: expected $ANDROID_EXPECTED_LABEL got application=${observed_label:-missing} activity=${observed_launcher_label:-missing}"
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
if [[ -n ${ANDROID_DEX_FILE:-} ]]; then
    expected_dex_sha=$(sha256sum "$ANDROID_DEX_FILE" | awk '{print $1}')
    observed_dex_sha=$(unzip -p "$signed" classes.dex | sha256sum | awk '{print $1}')
    [[ "$observed_dex_sha" == "$expected_dex_sha" ]] ||
        fail "finished APK direct DEX payload differs from its declared input"
fi
if [[ "$expected_activity" != android.app.NativeActivity ]]; then
    unzip -p "$signed" classes.dex > "$work/finished-classes.dex"
    java -jar "$ANDROID_BAKSMALI_JAR" disassemble "$work/finished-classes.dex" -o "$work/class-disassembly"
    activity_path=${expected_activity//.//}
    activity_source="$work/class-disassembly/$activity_path.smali"
    [[ -f "$activity_source" ]] || fail "declared NativeActivity subclass is absent from finished DEX"
    grep -Fxq '.super Landroid/app/NativeActivity;' "$activity_source" ||
        fail "declared launcher does not directly extend framework NativeActivity"
fi

apk_sha=$(sha256sum "$signed" | awk '{print $1}')
manifest_sha=$(sha256sum "$manifest" | awk '{print $1}')
native_sha=$(sha256sum "$native_library" | awk '{print $1}')
require_no_dex=${ANDROID_REQUIRE_NO_DEX:-1}
[[ "$require_no_dex" == 0 || "$require_no_dex" == 1 ]] ||
    fail "ANDROID_REQUIRE_NO_DEX must be 0 or 1"
source_commit=$(printf '%s' "${ANDROID_SOURCE_COMMIT:-unknown}" | tr '[:upper:]' '[:lower:]')
expected_label=${ANDROID_EXPECTED_LABEL:-}
for observed_value_name in \
    libname observed_label observed_launcher_label signature_mode source_commit
do
    require_plain_tsv_value "$observed_value_name" "${!observed_value_name}"
done
receipt="${output%.apk}.receipt.tsv"
# Prepare both publications on the output filesystem. The signed candidate may
# have been built under RUNNER_TEMP on another mount; moving it directly into
# place would then degrade to a non-atomic, destructive copy.
publish_stage=$(mktemp -d "$output_dir/.android-ndk-publish.XXXXXXXX")
cp -- "$signed" "$publish_stage/artifact.apk"
staged_sha=$(sha256sum "$publish_stage/artifact.apk" | awk '{print $1}')
[[ "$staged_sha" == "$apk_sha" ]] ||
    fail "publication staging changed signed APK content"

material="$work/material.tsv"
{
    printf 'schema\t%s\n' "$schema_id"
    printf 'schema_sha256\t%s\n' "$schema_sha"
    printf 'package\t%s\n' "$observed_package"
    printf 'version_code\t%s\n' "$observed_version_code"
    printf 'version_name\t%s\n' "$ANDROID_VERSION_NAME"
    printf 'min_sdk\t%s\n' "$ANDROID_MIN_SDK"
    printf 'target_sdk\t%s\n' "$ANDROID_TARGET_SDK"
    printf 'expected_launcher_label\t%s\n' "$expected_label"
    printf 'require_no_dex\t%s\n' "$require_no_dex"
    printf 'abi\t%s\n' "$abi"
    printf 'native_library\t%s\n' "$libname"
    printf 'source_date_epoch\t%s\n' "$source_date_epoch"
    printf 'approved_source_date_epoch\t%s\n' "$approved_source_date_epoch"
    printf 'timestamp_normalization\t%s\n' "$timestamp_normalization"
    printf 'mode_normalization\t%s\n' "$mode_normalization"
    printf 'entry_order\t%s\n' "$entry_order"
    printf 'zip_metadata\t%s\n' "$zip_metadata"
    printf 'source_commit\t%s\n' "$source_commit"
    printf 'signature_policy\t%s\n' "$signature_policy"
    printf 'signature_mode\t%s\n' "$signature_mode"
    printf 'manifest_sha256\t%s\n' "$manifest_sha"
    printf 'resource_closure_sha256\t%s\n' "$resource_closure_sha"
    printf 'asset_closure_sha256\t%s\n' "$asset_closure_sha"
    printf 'native_sha256\t%s\n' "$native_sha"
    if [[ -n ${ANDROID_DEX_FILE:-} ]]; then
        printf 'launcher_activity\t%s\n' "$observed_activity"
        printf 'dex_sha256\t%s\n' "$observed_dex_sha"
        printf 'baksmali_sha256\t%s\n' "${oracle_sha:-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855}"
    fi
    printf 'signer_cert_sha256\t%s\n' "$apk_cert"
    printf 'packager_sha256\t%s\n' "$packager_sha"
    printf 'verifier_sha256\t%s\n' "$verifier_sha"
    printf 'aapt2_sha256\t%s\n' "$aapt2_sha"
    printf 'zipalign_sha256\t%s\n' "$zipalign_sha"
    printf 'apksigner_sha256\t%s\n' "$apksigner_sha"
    printf 'apksigner_jar_sha256\t%s\n' "$apksigner_jar_sha"
    printf 'android_jar_sha256\t%s\n' "$android_jar_sha"
    printf 'zip_sha256\t%s\n' "$zip_sha"
} > "$material"
material_sha=$(sha256sum "$material" | awk '{print $1}')

{
    cat "$material"
    printf 'material_sha256\t%s\n' "$material_sha"
    printf 'launcher_label\t%s\n' "$observed_label"
    printf 'launcher_activity_label\t%s\n' "${observed_launcher_label:-$observed_label}"
    printf 'unsigned_apk_sha256\t%s\n' "$unsigned_apk_sha"
    printf 'aligned_apk_sha256\t%s\n' "$aligned_apk_sha"
    printf 'apk_sha256\t%s\n' "$apk_sha"
} > "$publish_stage/receipt.tsv"

"$grease_runtime" "$verifier_file" \
    "$publish_stage/receipt.tsv" "$publish_stage/artifact.apk"

# Both renames stay on one filesystem. A failed or interrupted stage/copy
# cannot damage the previous output. Consumers must still compare the receipt
# apk_sha256 with the finished APK: two paths are not jointly atomic.
mv -f -- "$publish_stage/artifact.apk" "$output"
mv -f -- "$publish_stage/receipt.tsv" "$receipt"

printf 'ANDROID_NDK_APK\tPASS\n'
printf 'PACKAGE\t%s\n' "$observed_package"
printf 'VERSION_CODE\t%s\n' "$observed_version_code"
printf 'ABI\t%s\n' "$abi"
printf 'APK_SHA256\t%s\n' "$apk_sha"
printf 'SIGNER_SHA256\t%s\n' "$apk_cert"
printf 'RECEIPT\t%s\n' "$receipt"
