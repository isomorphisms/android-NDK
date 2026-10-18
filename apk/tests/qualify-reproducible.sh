#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
    printf 'android-NDK reproducibility qualification failed: %s\n' "$*" >&2
    exit 1
}

[[ $# -eq 4 ]] || {
    printf 'usage: %s MANIFEST NATIVE_LIBRARY ABI OUTPUT_DIRECTORY\n' "$0" >&2
    exit 2
}
manifest=$1
native=$2
abi=$3
output=$4
directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
packager=$(realpath "$directory/../build-nativeactivity-apk.sh")
verifier=$(realpath "$directory/../verify-nativeactivity-receipt.sh")
schema=$(realpath "$directory/../nativeactivity-receipt-v2.schema.tsv")

mkdir -p "$output"
epoch=1710200000
source_revision=${GITHUB_SHA:-0000000000000000000000000000000000000000}
[[ "$source_revision" =~ ^[0-9a-fA-F]{40}([0-9a-fA-F]{24})?$ ]] ||
    fail "qualification source revision is not exact"

receipt_value() {
    local receipt=$1
    local field=$2
    awk -F '\t' -v field="$field" '$1 == field { print $2 }' "$receipt"
}

make_equivalent_root() {
    local root=$1
    local order=$2
    local native_mode=$3
    local stamp=$4

    mkdir -p "$root/res/values" "$root/assets/nested" "$root/input"
    if [[ "$order" == forward ]]; then
        printf '%s\n' '<resources><string name="alpha">one</string></resources>' > "$root/res/values/a.xml"
        printf '%s\n' '<resources><string name="omega">two</string></resources>' > "$root/res/values/z.xml"
        printf 'alpha\n' > "$root/assets/a.txt"
        printf 'omega\n' > "$root/assets/nested/z.txt"
    else
        printf '%s\n' '<resources><string name="omega">two</string></resources>' > "$root/res/values/z.xml"
        printf '%s\n' '<resources><string name="alpha">one</string></resources>' > "$root/res/values/a.xml"
        printf 'omega\n' > "$root/assets/nested/z.txt"
        printf 'alpha\n' > "$root/assets/a.txt"
    fi
    cp -- "$manifest" "$root/input/AndroidManifest.xml"
    cp -- "$native" "$root/input/$(basename -- "$native")"
    chmod "$native_mode" "$root/input/$(basename -- "$native")"
    if [[ "$native_mode" == 0644 ]]; then
        chmod 0700 "$root/res/values" "$root/assets/nested"
        chmod 0600 "$root/res/values/"*.xml "$root/assets/a.txt" "$root/assets/nested/z.txt"
    else
        chmod 0755 "$root/res" "$root/res/values" "$root/assets" "$root/assets/nested"
        chmod 0644 "$root/res/values/"*.xml "$root/assets/a.txt" "$root/assets/nested/z.txt"
    fi
    touch -d "$stamp" "$root/input/AndroidManifest.xml" "$root/input/$(basename -- "$native")"
    find "$root/res" "$root/assets" -exec touch -d "$stamp" {} +
}

run_package() {
    local selected_packager=$1
    local root=$2
    local timezone=$3
    local attempt=$4
    local destination=$5

    env \
        TZ="$timezone" \
        SOURCE_DATE_EPOCH="$epoch" \
        ANDROID_EXPECTED_SOURCE_DATE_EPOCH="$epoch" \
        ANDROID_SOURCE_COMMIT="$source_revision" \
        ANDROID_MIN_SDK=26 \
        ANDROID_RES_DIR="$root/res" \
        ANDROID_ASSET_DIR="$root/assets" \
        ANDROID_ATTEMPT_ID="$attempt" \
        bash "$selected_packager" \
            "$root/input/AndroidManifest.xml" \
            "$root/input/$(basename -- "$native")" \
            "$abi" "$destination"
}

first_root="$output/workspace-a"
second_root="$output/different/workspace-b"
make_equivalent_root "$first_root" forward 0755 '2020-01-02 03:04:05 UTC'
make_equivalent_root "$second_root" reverse 0644 '2025-06-07 08:09:10 +1400'

run_package "$packager" "$first_root" UTC attempt-a "$output/first.apk" > "$output/first.log"
run_package "$packager" "$second_root" Pacific/Kiritimati attempt-b "$output/second.apk" > "$output/second.log"
cmp -s "$output/first.apk" "$output/second.apk" ||
    fail "equivalent inputs did not produce identical signed APK bytes"
cmp -s "$output/first.receipt.tsv" "$output/second.receipt.tsv" ||
    fail "equivalent inputs did not produce identical canonical receipts"
bash "$verifier" "$output/first.receipt.tsv" "$output/first.apk" > "$output/verify-first.log"
bash "$verifier" "$output/second.receipt.tsv" "$output/second.apk" > "$output/verify-second.log"
if grep -Fq 'attempt-' "$output/first.receipt.tsv"; then
    fail "attempt metadata entered the canonical receipt"
fi
zipinfo -v "$output/first.apk" > "$output/archive.txt"
if grep -Fq 'Unix UID/GID' "$output/archive.txt"; then
    fail "builder UID/GID ZIP metadata entered a qualified package"
fi
grep -Fq $'source_date_epoch\t1710200000' "$output/first.receipt.tsv"
grep -Fq $'approved_source_date_epoch\t1710200000' "$output/first.receipt.tsv"
grep -Fq $'signature_policy\tapk-signature-v2-only' "$output/first.receipt.tsv"
grep -Fq $'signature_mode\tv1-false,v2-true,v3-false' "$output/first.receipt.tsv"
grep -Fq $'timestamp_normalization\tsource-date-epoch-utc' "$output/first.receipt.tsv"
grep -Fq $'mode_normalization\tfiles-0644-directories-0755' "$output/first.receipt.tsv"
grep -Fq $'entry_order\tlc-all-c-relative-path' "$output/first.receipt.tsv"
grep -Fq $'zip_metadata\tstrip-uid-gid-extra' "$output/first.receipt.tsv"

changed_resource="$output/changed-resource"
cp -R -- "$first_root" "$changed_resource"
sed -i 's/>one</>changed</' "$changed_resource/res/values/a.xml"
run_package "$packager" "$changed_resource" UTC changed-resource "$output/changed-resource.apk" \
    > "$output/changed-resource.log"
[[ $(receipt_value "$output/first.receipt.tsv" resource_closure_sha256) != \
   $(receipt_value "$output/changed-resource.receipt.tsv" resource_closure_sha256) ]] ||
    fail "changed resource bytes preserved the resource closure"
[[ $(receipt_value "$output/first.receipt.tsv" material_sha256) != \
   $(receipt_value "$output/changed-resource.receipt.tsv" material_sha256) ]] ||
    fail "changed resource bytes preserved material identity"

changed_native="$output/changed-native"
cp -R -- "$first_root" "$changed_native"
printf '\0' >> "$changed_native/input/$(basename -- "$native")"
run_package "$packager" "$changed_native" UTC changed-native "$output/changed-native.apk" \
    > "$output/changed-native.log"
[[ $(receipt_value "$output/first.receipt.tsv" native_sha256) != \
   $(receipt_value "$output/changed-native.receipt.tsv" native_sha256) ]] ||
    fail "changed native bytes preserved native identity"
[[ $(receipt_value "$output/first.receipt.tsv" material_sha256) != \
   $(receipt_value "$output/changed-native.receipt.tsv" material_sha256) ]] ||
    fail "changed native bytes preserved material identity"

if bash "$verifier" "$output/first.receipt.tsv" "$output/changed-native.apk" \
    > "$output/mismatched-pair.log" 2>&1
then
    fail "mismatched receipt/APK pair passed verification"
fi
grep -Fq 'APK digest does not match receipt' "$output/mismatched-pair.log"

if env \
    SOURCE_DATE_EPOCH=$((epoch + 1)) \
    ANDROID_EXPECTED_SOURCE_DATE_EPOCH="$epoch" \
    ANDROID_SOURCE_COMMIT="$source_revision" \
    ANDROID_MIN_SDK=26 \
    bash "$packager" "$manifest" "$native" "$abi" "$output/wrong-epoch.apk" \
    > "$output/wrong-epoch.log" 2>&1
then
    fail "wrong source epoch unexpectedly passed"
fi
grep -Fq 'SOURCE_DATE_EPOCH does not match approved epoch' "$output/wrong-epoch.log"
test ! -e "$output/wrong-epoch.apk"

if env \
    SOURCE_DATE_EPOCH=invalid \
    ANDROID_EXPECTED_SOURCE_DATE_EPOCH="$epoch" \
    ANDROID_SOURCE_COMMIT="$source_revision" \
    ANDROID_MIN_SDK=26 \
    bash "$packager" "$manifest" "$native" "$abi" "$output/invalid-epoch.apk" \
    > "$output/invalid-epoch.log" 2>&1
then
    fail "invalid source epoch unexpectedly passed"
fi
grep -Fq 'SOURCE_DATE_EPOCH must be an integer' "$output/invalid-epoch.log"

if env \
    SOURCE_DATE_EPOCH="$epoch" \
    ANDROID_EXPECTED_SOURCE_DATE_EPOCH="$epoch" \
    ANDROID_SOURCE_COMMIT="$source_revision" \
    ANDROID_MIN_SDK=23 \
    bash "$packager" "$manifest" "$native" "$abi" "$output/old-api.apk" \
    > "$output/old-api.log" 2>&1
then
    fail "incompatible API floor unexpectedly passed"
fi
grep -Fq 'reproducible signing requires API 24' "$output/old-api.log"

if env \
    SOURCE_DATE_EPOCH="$epoch" \
    ANDROID_EXPECTED_SOURCE_DATE_EPOCH="$epoch" \
    ANDROID_SOURCE_COMMIT="$source_revision" \
    ANDROID_MIN_SDK=26 \
    ANDROID_EXPECTED_CERT_SHA256=0000000000000000000000000000000000000000000000000000000000000000 \
    bash "$packager" "$manifest" "$native" "$abi" "$output/wrong-signer.apk" \
    > "$output/wrong-signer.log" 2>&1
then
    fail "wrong signer unexpectedly passed"
fi
grep -Fq 'keystore certificate changed' "$output/wrong-signer.log"

mutants="$output/mutants"
mkdir -p "$mutants"
cp -- "$schema" "$mutants/nativeactivity-receipt-v2.schema.tsv"
cp -- "$verifier" "$mutants/verify-nativeactivity-receipt.sh"
cp -- "$packager" "$mutants/old-packager.sh"
sed -i \
    's/chmod 0644 "\$work\/payload\/lib\/\$abi\/\$libname"/chmod --reference="\$native_library" "\$work\/payload\/lib\/\$abi\/\$libname"/' \
    "$mutants/old-packager.sh"
bash -n "$mutants/old-packager.sh"
run_package "$mutants/old-packager.sh" "$first_root" UTC old-a "$output/old-first.apk" \
    > "$output/old-first.log"
run_package "$mutants/old-packager.sh" "$second_root" Pacific/Kiritimati old-b "$output/old-second.apk" \
    > "$output/old-second.log"
if cmp -s "$output/old-first.apk" "$output/old-second.apk"; then
    fail "old-packager mutant unexpectedly preserved package bytes"
fi

cp -- "$packager" "$mutants/zip-metadata-packager.sh"
sed -i 's/zip_options=(-X)/zip_options=()/' "$mutants/zip-metadata-packager.sh"
run_package "$mutants/zip-metadata-packager.sh" "$first_root" UTC zip-metadata \
    "$output/zip-metadata.apk" > "$output/zip-metadata.log"
zipinfo -v "$output/zip-metadata.apk" > "$output/zip-metadata-archive.txt"
grep -Fq 'Unix UID/GID' "$output/zip-metadata-archive.txt" ||
    fail "ZIP metadata mutant did not expose builder identity"

printf 'android-NDK reproducible NativeActivity qualification: PASS\n'
printf 'MATERIAL_SHA256\t%s\n' "$(receipt_value "$output/first.receipt.tsv" material_sha256)"
printf 'APK_SHA256\t%s\n' "$(receipt_value "$output/first.receipt.tsv" apk_sha256)"
