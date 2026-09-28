# TAB_P10 physical Android / AArch64 receipt

Copied from `fuego-ironworks/idric-arm-thumb`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/8  
Original cross-index: https://github.com/fuego-ironworks/idric-arm-thumb/issues/104

## Physical device receipt

The published DEX/JNI tablet payload was executed on the physical device with:

```text
model             TAB_P10
hardware          sun65iw1p1
ABI               arm64-v8a
Android release   15
Android SDK       35
fingerprint       SVITOO/TAB_P10_ROW/TAB_P10_ROW:15/AP3A.241105.008/20250910SMR2:user/release-keys
```

## Exact payload identity

```text
release tag       reddit-android-513d3515083e
release target    513d3515083edaf723a60292d8d333b7171469cb
workflow run      35138107496
backend sha       513d3515083edaf723a60292d8d333b7171469cb
bundle sha256     3cb14b45cf6a45834bfe94f87bd27c11b007f42b306ffc80d3126f23eb5bdbbd
classes.dex       286456839513ef4d441aa4acd6b3273ec61382cbb4619ab37277f42158e32be5
JNI library       f3ce55bccce48a70f3d38901aa32292d89edef7e6c366d6c289a73f134c76a3c
```

## Physical execution result

The receipt established:

- the published tablet archive matched its retained SHA-256;
- ART loaded the published `classes.dex`;
- the AArch64 native library loaded;
- the DEX -> JNI call boundary executed;
- URL encoding/output path passed;
- the native missing-token error path passed.

Recorded boundary fields:

```text
url_boundary           PASS
missing_token_boundary PASS
network_search         SKIP credentials_not_present
```

No compilation occurred on the tablet.

## Unclaimed

The receipt did **not** claim:

- authenticated Reddit HTTPS/OAuth execution;
- JSON parsing/TSV output from a live credentialed response;
- GitHub-level immutable release storage.

Those application-level omissions do not weaken the hardware/runtime facts: this is a real `arm64-v8a` Android 15 device executing the released ART/JNI payload.

## Canonical source

- physical receipt comment on https://github.com/fuego-ironworks/idric-arm-thumb/pull/65
