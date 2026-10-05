# SPMySQL.framework

The SPMySQL Framework is intended to provide a stable MySQL connection framework, with the ability to run text-based queries and rapidly retrieve result sets with conversion from MySQL data types to Cocoa objects.

SPMySQL.framework has an interface loosely based around that provided by MCPKit by Serge Cohen and Bertrand Mansion ([http://mysql-cocoa.sourceforge.net/](http://mysql-cocoa.sourceforge.net/)), and in particular the heavily modified Sequel Pro version ([https://sequelpro.com/](https://sequelpro.com/)). It is a full rewrite of the original framework, although it includes code from patches implementing the following Sequel Pro functionality, largely contributed by Hans-Jörg Bibiko, Stuart Connolly, Jakob Egger and Rowan Beentje:

* Connection locking (Jakob et al.)
* Ping & keepalive (Rowan et al.)
* Query cancellation (Rowan et al.)
* Delegate setup (Stuart et al.)
* SSL support (Rowan et al.)
* Connection checking (Rowan et al.)
* Version state (Stuart et al.)
* Maximum packet size control (Hans et al.)
* Result multithreading and streaming (Rowan et al.)
* Improved encoding support & switching (Rowan et al.)
* Database structure; moved to inside the app (Hans et al.)
* Query reattempts and error-handling approach (Rowan et al.)
* Geometry result class (Hans et al.)
* Connection proxy (Stuart et al.)

## Integration

SPMySQL.framework can be added to your project as a standard Cocoa framework, or the entire project
can be added as a subproject in Xcode.

To add as a subproject in Xcode:

1. Add the SPMySQL framework's `.xcodeproj` to your current project
2. Choose an existing target, Get Info, and under direct dependenies add a new dependency. Choose the SPMySQL.framework target from the sub-project.
3. Expand the subproject to see its child target - SPMySQL.framework. Drag this to the "Link Binary With Libraries" build phase of any targets using the framework.
4. If you don't have a Copy Frameworks phase, add one; drag the SPMySQL.framework child target to this phase.
5. In your build settings, add a User Header Search Path; make it a recursive path to the SPMySQL project folder location (for example `${PROJECT_DIR}/Frameworks/SPMySQLFramework`). This should allow you to `#include "SPMySQL.h"` and have everything function.

As a last resort jump onto IRC and join #sequel-pro on irc.freenode.net and any of the
developers will be more than happy to help you out.

## Native Apple Silicon builds

The Xcode project targets `arm64` and macOS 12 or later. The bundled
`MySQL Client Libraries/lib/libmysqlclient.a` contains both `arm64` and `x86_64`
slices; its TLS implementation is statically included, so the framework does
not require a Homebrew MySQL, OpenSSL, or MariaDB installation at runtime.

The client remains MySQL **5.5.56**, matching the existing public headers and
the `MYSQL` / `NET` structures used by this framework. This architecture port
does not change its supported authentication methods or TLS protocols.

To rebuild the library, install Xcode command-line tools and CMake **3.x**
(the upstream CMake files predate the policy removals in CMake 4), then run:

```sh
./build-mysql-client.sh
```

The script downloads the [official MySQL 5.5.56 source](https://github.com/mysql/mysql-server/tree/mysql-5.5.56),
verifies SHA-256 `deeece396b04bc931fb4c4d3188281b591ea097e47a400ef91242253b199b41b`,
applies the checked-in patches, and builds each architecture separately using
the selected Xcode SDK. It replaces the library only after all slices build.
Build logs and intermediate files are kept in the temporary build directory.
The source is GPLv2, as are its bundled yaSSL/TaoCrypt libraries; see the
upstream `COPYING` files for their licenses.

For an ARM-only rebuild that does not execute Intel build tools through
Rosetta, use `./build-mysql-client.sh -a arm64`. Set `CMAKE=/path/to/cmake`
to use a portable CMake 3 installation. `-s` accepts a pristine local 5.5.56
source tree; `-b` selects an intermediate directory and `-o` selects an output
directory containing `include/` and `lib/`.

The patches recognize the LP64 ARM ABI, preserve the existing backported
field types, and make the pure-C yaSSL runtime's virtual-call handler safe for
the modern linker. Cached Objective-C method calls use explicit signatures,
including `BOOL` return values, to match the Apple Silicon calling convention.

After building the framework, the optional smoke test below checks string
escaping, UTF-8 data, 64-bit values, SQL NULL, and background result streaming
against an already-running disposable local server. It executes only SELECTs
and uses the local `root` account with an empty password:

```sh
./test-native-client.sh /path/to/SPMySQL.framework /path/to/test-mysql.sock
```

## License

Copyright (c) 2018 Rowan Beentje (rowan.beent.je) & the Sequel Pro team. All rights reserved.

SPMySQLFramework is free and open source software, licensed under [MIT](https://opensource.org/licenses/MIT). See [LICENSE](https://github.com/sequelpro/sequelpro/blob/master/Frameworks/SPMySQLFramework/LICENSE) for full details.
