# Native Apple Silicon dependencies

The application uses the checked-in frameworks directly; an ordinary app build does
not download dependencies. The active application and test frameworks below were
rebuilt for `arm64`, macOS 12 or later, with Xcode 27 / macOS 27 SDK.

Sparkle is retained in the repository and rebuild workflow as a historical archive.
It is no longer linked, embedded, or initialized by this fork. Update actions open
the [fork release page](https://github.com/codezi/sequelpro/releases) in the browser.
The archived Sparkle binary is the unmodified official universal `arm64`/`x86_64`
release.

| Framework | Upstream source / revision | License |
| --- | --- | --- |
| FeedbackReporter | [tcurdt/feedbackreporter](https://github.com/tcurdt/feedbackreporter/tree/92230feade69e1298cd5a8cbc0c8ddd2dc939934) `92230feade69e1298cd5a8cbc0c8ddd2dc939934` | Apache 2.0 |
| Growl | [growl/growl](https://github.com/growl/growl/tree/c01798eefb52ff95dd1e548ad5dd24e00f59ef20) `c01798eefb52ff95dd1e548ad5dd24e00f59ef20` | BSD |
| ShortcutRecorder | [Kentzo/ShortcutRecorder](https://github.com/Kentzo/ShortcutRecorder/tree/7f29c1820861541c4b59890110e8147526f9ac92) `7f29c1820861541c4b59890110e8147526f9ac92` | BSD |
| UniversalDetector | [MacPaw/universal-detector](https://github.com/MacPaw/universal-detector/tree/4eb832d999628edcd3d134e46bd35357c8c99a85) `4eb832d999628edcd3d134e46bd35357c8c99a85` | LGPL 2.1 or later |
| OCMock (tests) | [erikdoe/ocmock](https://github.com/erikdoe/ocmock/tree/2c0bfd373289f4a7716db5d6db471640f91a6507) `2c0bfd373289f4a7716db5d6db471640f91a6507` (3.9.4) | Apache 2.0 |
| Sparkle (historical archive) | [Sparkle 1.27.3 release](https://github.com/sparkle-project/Sparkle/releases/tag/1.27.3) | MIT and bundled third-party notices |

Growl's two source dependencies are also pinned:

- [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket/tree/5ddba5e72f38e56010dbfac08b44478ee5000c0c), revision `5ddba5e72f38e56010dbfac08b44478ee5000c0c` (public domain/BSD).
- [ISO8601DateFormatter](https://github.com/boredzo/iso-8601-date-formatter/tree/b1d40da20608ca4613994628bc948207ccfcdfae), revision `b1d40da20608ca4613994628bc948207ccfcdfae` (BSD).

The complete upstream license notices are in `licenses/`. UniversalDetector remains
a separate dynamically linked framework; its exact source is linked above and
fetched by the rebuild script. Preserve the LGPL notice and make the corresponding
source available when redistributing the application.

## Rebuild

Run from this repository on a Mac with Xcode and command-line tools installed:

```sh
Frameworks/NativeBuild/rebuild.sh
```

The script fetches each exact revision, applies the checked-in patches, builds the
five active application/test frameworks, validates the historical Sparkle archive
SHA-256, and replaces all six repository bundles. Retaining Sparkle in this rebuild
workflow does not add it to the application.
It fails if an existing cache points at a different revision. Build logs and source
checkouts remain in `.work/native-frameworks/` by default. For a separate output
without changing checked-in bundles:

```sh
NATIVE_FRAMEWORK_CACHE=/tmp/sequelpro-native-framework-cache \
NATIVE_FRAMEWORK_OUTPUT=/tmp/sequelpro-native-framework-output \
Frameworks/NativeBuild/rebuild.sh
```

Rebuilt public headers have trailing whitespace removed, and rebuilt bundles are
ad-hoc signed. The archived Sparkle files and signature are preserved. Xcode signs
the active embedded frameworks when building the app. The historical Sparkle
archive has SHA-256
`b4c70198aba86a65dc04550fbd0a97243a9ba3b98d73d138c877347f27920952`.

## Compatibility changes

- ShortcutRecorder uses the last legacy implementation before the 2.x API rewrite,
  retaining `KeyCombo`, `SRRecorderCell`, and the archived nib classes.
- FeedbackReporter retains manual-reference-counted callers, the mutable preferences
  anonymization delegate, and the original `targetUrlForFeedbackReport` delegate
  selector. The framework itself uses ARC. Reports still use its confirmation UI.
- Growl's frozen compiler-version guard is removed. Modern XPC objects no longer
  need the old `NSObject` typedef annotation. CocoaAsyncSocket compiles with ARC.
  An unused OpenSSL include/type from already-disabled encryption code is removed;
  hashing continues to use the system CommonCrypto implementation.
- OCMock's upstream test-only OCHamcrest package reference is omitted for the
  framework build; OCMock's implementation and app test APIs are unchanged.
- The archived Sparkle 1.27.3 bundle includes its original `SUUpdater` API and
  native relauncher for historical reference. Neither is used by this fork.

## Native smoke check

```sh
Frameworks/NativeBuild/smoke-test.sh
```

This compiles and runs an arm64 process against the actual checked-in binaries. It
checks UTF-8 and ASCII detection/reset, the legacy shortcut key-combination ABI and
classes, FeedbackReporter initialization, Growl class loading, and OCMock
method interception. It does not submit reports, send notifications, or check for
updates. Passing an alternate framework directory tests separate rebuild output.

After building the app, the AppKit tracking regression check runs against its real
PSMTabBar framework:

```sh
Frameworks/NativeBuild/tracking-smoke.sh
# Or pass a different Xcode products directory as the first argument.
```

It creates an offscreen window, lays out three tabs, repeats 50 resize/update
cycles, toggles close buttons, restores archives containing legacy tracking tags,
and tears down the views. The original implementation fails this check because
AppKit rejects tracking tag zero; the updated implementation passes. The fix also
stops persisting tracking handles, which are valid only for their current view.
