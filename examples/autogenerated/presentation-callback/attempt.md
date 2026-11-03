# Native presentation callback

Purpose: let framework Buttons dispatch an actual view identity into a consumer's
existing controller. The reusable class owns no application, history or network.

Types: `View.OnClickListener.onClick : View → IO ()`. The Android View carries
the control identity; the application checks availability and source revision.
The callback has no pointers serialized into fields and grants no capability.

Backend: existing `FrameworkClass`/`NativeCallback` typed DEX plans. This is a
JNI declaration, not checked application semantics. ICK compiles native consumers.
No Java/Kotlin/Compose/Gradle/d8 or hand-written smali produces this DEX.

Execution and negative controls are recorded in the accompanying build receipt.
The generic declaration needs no new Idriç language capability. App adapters
must separately qualify their semantic action dispatch and lifecycle ownership.
