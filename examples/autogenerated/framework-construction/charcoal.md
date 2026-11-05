# Framework qualification presentation

The target constructor fixture, source-address observer and alternate receiver
declare the shared Theme.Charcoal explicitly. Their existing package identities,
public test signer, candidate DEX, source-intent checks and text/selection/reflow
mutants remain intact. The instrumentation packager compiles the same shared
resources once and links them into every fixture package.

The independent ReaderChecks observer now reads the actual framework TextView's
text color before changing any state and requires opaque F4F4F4. It never sets
that color on the candidate. A missing theme therefore fails at the existing
registered application boundary. This is an observation-only extension to the
existing smali harness, not a candidate generator or Java/Kotlin implementation.

The first API34 run41968338461 reached the real TextView check and rejected its
color. The instrumentation had supplied its raw package Context, which does not
model Activity theme application. It now creates a ContextThemeWrapper from the
target's actual ApplicationInfo.theme. A missing or changed manifest theme still
affects the actual candidate constructor; the observer never sets its color or
chooses a theme resource independently. Failure now reports the observed ARGB.
Fresh current-source Android execution must establish the repaired fixture.
The unchanged positive candidate is also repackaged with only the manifest theme
removed, which must fail the palette check before the original recovery case.

Run41970666811 observes actual ARGB b3ffffff even with the declared theme bound.
Android's default TextView textAppearance bypasses textColorPrimary. Repair the
shared owner with Widget.Charcoal.TextView and an explicit stateful textColor,
referenced by both application and dialog themes. The oracle retains exact F4;
neither it nor the candidate constructor supplies a replacement color. Fresh
execution must qualify this shared implementation repair.

The framework-effects producer supplies actual Android API34 execution. Until
that exact source runs, these changes are not accepted. The retained IB screen
fixture still binds its older application source and resources; it is not the
current IB charcoal candidate. Historical DEX overlay builders remain test
fixtures with temporary keys and are not approved C67 upgrades. Their separate
resource integration and full API29/34 startup/rotation coverage remain pending.
