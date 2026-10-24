#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
    printf 'android-NDK receipt verification failed: %s\n' "$*" >&2
    exit 1
}

[[ $# -eq 2 ]] || {
    printf 'usage: %s RECEIPT APK\n' "$0" >&2
    exit 2
}
receipt=$1
apk=$2
[[ -f "$receipt" ]] || fail "missing receipt: $receipt"
[[ -f "$apk" ]] || fail "missing APK: $apk"

directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
schema_id=$(awk -F '\t' '$1 == "schema" { print $2 }' "$receipt")
case "$schema_id" in
    android-ndk-nativeactivity-apk-v2) schema_file="$directory/nativeactivity-receipt-v2.schema.tsv" ;;
    android-ndk-nativeactivity-apk-v3) schema_file="$directory/nativeactivity-receipt-v3.schema.tsv" ;;
    *) fail "unsupported receipt schema: $schema_id" ;;
esac
[[ -f "$schema_file" ]] || fail "missing schema: $schema_file"

work=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/android-ndk-receipt.XXXXXX")
trap 'rm -rf "$work"' EXIT

tail -n +2 "$schema_file" | cut -f1 > "$work/expected-fields"
awk -F '\t' 'NF != 2 { exit 1 } { print $1 }' "$receipt" > "$work/actual-fields" ||
    fail "receipt is not strict two-column TSV"
cmp -s "$work/expected-fields" "$work/actual-fields" ||
    fail "receipt fields or field order do not match the schema"

value() {
    local field=$1
    awk -F '\t' -v field="$field" '$1 == field { print $2 }' "$receipt"
}

schema_sha=$(sha256sum "$schema_file" | awk '{print $1}')
[[ $(value schema_sha256) == "$schema_sha" ]] ||
    fail "receipt schema digest does not match the maintained schema"

while IFS=$'\t' read -r field role meaning; do
    [[ "$field" == field ]] && continue
    case "$field" in
        *_sha256)
            [[ $(value "$field") =~ ^[0-9a-f]{64}$ ]] ||
                fail "$field is not a lowercase SHA-256 digest"
            ;;
    esac
    if [[ "$role" == material ]]; then
        awk -F '\t' -v field="$field" '$1 == field' "$receipt" >> "$work/material.tsv"
    fi
done < "$schema_file"

material_sha=$(sha256sum "$work/material.tsv" | awk '{print $1}')
[[ $(value material_sha256) == "$material_sha" ]] ||
    fail "material digest does not match the receipt's material rows"

apk_sha=$(sha256sum "$apk" | awk '{print $1}')
[[ $(value apk_sha256) == "$apk_sha" ]] ||
    fail "APK digest does not match receipt: expected $(value apk_sha256) got $apk_sha"

if [[ "$schema_id" == android-ndk-nativeactivity-apk-v3 ]]; then
    unzip -p "$apk" classes.dex > "$work/classes.dex" || fail "missing declared DEX payload"
    dex_sha=$(sha256sum "$work/classes.dex" | awk '{print $1}')
    [[ "$dex_sha" == $(value dex_sha256) ]] || fail "DEX digest does not match receipt"
fi

printf 'ANDROID_NDK_RECEIPT\tPASS\n'
printf 'MATERIAL_SHA256\t%s\n' "$material_sha"
printf 'APK_SHA256\t%s\n' "$apk_sha"
