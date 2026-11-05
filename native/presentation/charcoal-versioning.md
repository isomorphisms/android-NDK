# Charcoal resource API boundaries

Porthole's actual SDK lint exposed four NewApi errors in the preceding E8
resource at its retained API26 floor. Keep the lint check and the API floor.
The base theme now contains only attributes valid on the API19 consumer floor.
Platform windows layer Material/API21 controls, API23 status icon policy,
API27 navigation icon policy, API29 force-dark policy and API31 splash policy
through explicit version-qualified style inheritance. Dialog force-dark policy
is likewise introduced at API29. No lint suppression or raised minSdk is used.

The seven resource files form one contract and must be copied/compiled together.
Every version inherits the same neutral roles and the stateful default TextView
correction. API29/API34 resolve the same colors, icon flags and force-dark policy
as before; actual default-view, dialog/window and both-mode appearance checks
must requalify the new resource head. The C header and color values are unchanged.

The Android resource qualifier/inheritance design follows
https://developer.android.com/develop/ui/views/theming/themes#version-specific.
This is a candidate implementation until the existing SDK lint consumer,
resource-copy negative controls and Android execution pass. No new Gradle
project, Java/Kotlin source, framework or startup work is introduced.
