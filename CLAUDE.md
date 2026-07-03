# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SIPp is a SIP protocol test tool for generating and handling SIP traffic. It uses XML scenario files to define test sequences and can operate as both a SIP client and server for load testing and protocol validation.

## Build System

SIPp uses GNU Autotools (autoconf/automake):

```bash
# Configure with optional features
./configure --with-pcap --with-sctp

# Common configure options:
# --with-openssl    Enable OpenSSL/TLS support
# --with-pcap       Enable pcap playback support
# --with-rtpstream  Enable RTP streaming
# --with-sctp       Enable SCTP transport
# --with-gsl        Enable GNU Scientific Library support

# On this system (macOS), OpenSSL is located at:
# /opt/homebrew/opt/openssl@3.6
# To build with OpenSSL support:
./configure --with-openssl --with-pcap CPPFLAGS="-I/opt/homebrew/opt/openssl@3.6/include" LDFLAGS="-L/opt/homebrew/opt/openssl@3.6/lib"

# Build
make

# Run tests
make check
```

### Build Notes for Modern macOS/OpenSSL 3.x

The original codebase from 2013 requires modifications to build on modern systems:

1. **OpenSSL 3.x compatibility**: `configure.ac` was updated to check for `SSL_CTX_new` and `EVP_EncryptInit` instead of deprecated functions (`SSL_library_init`, `CRYPTO_num_locks`)

2. **C++ namespace conflicts**: Modern C++ stdlib defines `std::bind` which conflicts with the socket `bind()` system call. Fixed by using `::bind()` to explicitly call the global function in:
   - `src/socket.cpp` (2 locations)
   - `src/sipp.cpp` (2 locations)

3. **String literal concatenation**: Fixed missing space in `src/logger.cpp:215` between string literal and macro

4. **epoll detection**: Replaced autoconf-archive macros with simple platform detection since epoll is Linux-only

If you need to regenerate the configure script after modifying `configure.ac`:
```bash
autoreconf -ivf

# Run tests
make check  # Runs sipp_unittest

# Run the binary
./sipp -h  # Show help
```

The build system generates two binaries:
- `sipp` - Main SIP test tool executable
- `sipp_unittest` - Unit test runner

## Code Architecture

### Core Components

**Scenario Engine** (`scenario.hpp/cpp`, `message.hpp/cpp`)
- Parses XML scenario files (validated against `sipp.dtd`)
- Defines message types: SEND, RECV, PAUSE, NOP, SENDCMD, RECVCMD
- Supports multiple operating modes:
  - `MODE_CLIENT` / `MODE_SERVER` - Basic client/server modes
  - `MODE_3PCC_*` - Third-party call control modes (A/B controller, passive)
  - `MODE_MASTER` / `MODE_SLAVE` - Extended master/slave orchestration

**Call Management** (`call.hpp/cpp`, `deadcall.hpp/cpp`)
- Each call instance represents one SIP dialog
- Implements task/listener/socketowner pattern for event-driven execution
- Handles SIP transaction state and retransmissions
- Key constants:
  - `UDP_MAX_RETRANS_INVITE_TRANSACTION = 5`
  - `UDP_MAX_RETRANS_NON_INVITE_TRANSACTION = 9`
  - `SIP_TRANSACTION_TIMEOUT = 32000` ms
  - `DEFAULT_T2_TIMER_VALUE = 4000` ms

**Task Scheduling** (`task.hpp/cpp`)
- Hierarchical timing wheel implementation (Varghese & Lauck algorithm)
- Three-level wheel structure for efficient timer management
- Supports 32-bit timer values through cascading wheels

**Socket Management** (`socket.hpp/cpp`, `socketowner.hpp`, `listener.hpp`)
- Abstracts transport layer (UDP, TCP, SCTP, TLS)
- Uses epoll on Linux when available (`HAVE_EPOLL`)
- Platform-specific socket handling for portability

**Statistics** (`stat.hpp/cpp`)
- Tracks call metrics, response times, call length distribution
- Generates performance reports

**Actions** (`actions.hpp/cpp`)
- Defines scenario actions: regex extraction (`ereg`), logging (`log`), exec commands
- Actions are triggered by message events in scenarios

**Variables** (`variables.hpp/cpp`)
- Variable substitution system for dynamic scenario content
- Used for injecting test data from CSV files

### Platform Support

Platform-specific defines are set in `configure.ac`:
- `__LINUX` - Linux systems
- `__DARWIN` - macOS
- `__HPUX` - HP-UX
- `__SUNOS` - Solaris/SunOS
- `__CYGWIN` - Cygwin on Windows
- `__OSF1` - Tru64 Unix

SCTP on Darwin requires special handling (no `netinet/sctp.h` header).

### Optional Features

Features are conditionally compiled via preprocessor defines:
- `_USE_OPENSSL` - TLS/SSL support (`sslcommon.h`, `sslinit.c`, `sslthreadsafe.c`)
- `PCAPPLAY` - pcap file playback (`prepare_pcap.h/c`, `send_packets.h/c`)
- `RTP_STREAM` - RTP media streaming (`rtpstream.hpp/cpp`)
- `USE_SCTP` - SCTP transport protocol
- `HAVE_GSL` - GNU Scientific Library for statistical distributions
- `HAVE_EPOLL` - Linux epoll support

### Authentication

SIPp supports SIP authentication challenges:
- MD5 digest authentication (`md5.h/c`, `auth.c`)
- AKA (Authentication and Key Agreement) for 3GPP (`milenage.h/c`, `rijndael.h/c`)
- Functions: `createAuthHeader()`, `verifyAuthHeader()`

### Auxiliary Components

- `infile.hpp/cpp` - CSV injection file handling
- `logger.hpp/cpp` - Logging subsystem
- `screen.hpp/cpp` - ncurses-based real-time display
- `watchdog.hpp/cpp` - Watchdog timer for detecting hangs
- `xp_parser.h/c` - XML parsing for scenarios
- `sip_parser.hpp/cpp` - SIP message parsing
- `time.hpp/cpp` - Time/timing utilities
- `comp.h/c` - Compression utilities

## Coding Style

From README.txt, the project enforces:
- 80-column line width
- 2-space indentation (NO tabs)
- Always use braces for conditionals, even single statements
- Emacs-like indentation style

Example:
```cpp
if (condition) {
  f();
} else {
  g();
}
```

## Testing

The unit test binary `sipp_unittest` is built from the same source as `sipp` but with a different main function (`sipp_unittest.cpp` vs `sipp.cpp`).

## Additional Files

- `pcap/` - Directory containing sample DTMF pcap files for testing
- `sipp.1` - Man page
- `cpplint.py` - Python linter for checking code style
- `LICENSE.txt` - GPLv3 license
- `THANKS` - Contributors list
