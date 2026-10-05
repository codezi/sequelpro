Sequel Pro <img alt="Logo" src="https://sequelpro.com/images/logo.png" align="right" height="50">
=======

Sequel Pro is a fast, easy-to-use Mac database management application for working with MySQL & MariaDB databases.

You can find more details on our website: [sequelpro.com](https://sequelpro.com)

![Screenshot](https://sequelpro.com/images/browse.png)

Build Instructions
=======

This checkout targets **Apple Silicon (arm64), macOS 12 or later**. Install
Xcode, open `sequel-pro.xcodeproj`, select the **Sequel Pro** scheme and **My Mac**,
then Run. Local builds use ad hoc signing and do not need the original team's
development certificate. The bundled app dependencies contain arm64 code; zlib
comes from macOS.

To build an optimized app from Terminal:

```sh
make native
open ".build/DerivedData/Build/Products/Release/Sequel Pro.app"
```

`make native` also verifies the arm64 slice of every embedded Mach-O binary,
checks for build-machine library dependencies, and verifies the app signature.
The resulting `.app` can be copied to Applications. This local build is ad hoc
signed, not Developer ID signed or notarized for distribution to other Macs.

Run the XCTest suite natively with `make native-test`. Use
`make native NATIVE_CONFIG=Debug` for a debug build, or `make verify-native` to
recheck the Release bundle. Build artifacts stay under `.build/`.

The app does not load the upstream Sparkle updater or contact its update feed.
**View Fork Releases…** in the application menu and **Preferences → Updates**
opens [this fork's GitHub Releases](https://github.com/codezi/sequelpro/releases)
for manual updates. Existing Sparkle preferences cannot re-enable the old updater.

Release builds do not regenerate translations or modify signed framework
resources. The historical `Distribution` configuration still requires the
original release signing identity; use `Release` for local builds.

Dependency source revisions, licenses, patches, and rebuild commands are recorded
in [Frameworks/NativeBuild/README.md](Frameworks/NativeBuild/README.md) and
[Frameworks/SPMySQLFramework/README.md](Frameworks/SPMySQLFramework/README.md).
The MySQL client retains its existing authentication and TLS support; this port
changes architecture and macOS compatibility, not database protocol support.

Contributing
=======

The best way to help the project is to use our [test builds](https://sequelpro.com/test-builds) and report any issues (both bugs and missing features) in [the issue tracker](https://github.com/sequelpro/sequelpro/issues). If you want to get more involved, then you can comment on issues written by other people or send us a pull request.

Please see our [projects page](https://github.com/sequelpro/sequelpro/projects). This lists the issues where we would most like your help. There are simple and difficult tasks there so new contributors should be able to get started.

License
=======

Copyright (c) 2002-2019 Sequel Pro & CocoaMySQL Teams. All rights reserved.

Sequel Pro is free and open source software, licensed under [MIT](https://opensource.org/licenses/MIT). See [LICENSE](https://github.com/sequelpro/sequelpro/blob/master/LICENSE) for full details.
