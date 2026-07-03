# SIPp
This is a clone of the [SIPp project on SourceForge](https://sipp.sourceforge.net/).  It has been built specifically for MacOS running on ARM architecture with OpenSSL and PCAP playback support, with the help of Claude Code.

## Updates
This version was built from [SIPp 3.3.990](https://sourceforge.net/projects/sipp/files/sipp/3.4/), with the following changes:

1. **OpenSSL 3.x compatibility**: `configure.ac` was updated to check for `SSL_CTX_new` and `EVP_EncryptInit` instead of deprecated functions (`SSL_library_init`, `CRYPTO_num_locks`).

2. **C++ namespace conflicts**: Modern C++ stdlib defines `std::bind` which conflicts with the socket `bind()` system call. Fixed by using `::bind()` to explicitly call the global function in:
   - `src/socket.cpp` (2 locations)
   - `src/sipp.cpp` (2 locations)

3. **String literal concatenation**: Fixed missing space in `src/logger.cpp:215` between string literal and macro.

4. **epoll detection**: Replaced autoconf-archive macros with simple platform detection since epoll is Linux-only.

## Building
See [CLAUDE.md](CLAUDE.md) for build instructions.  If you are looking for executables, see [binaries](binaries).

## Usage
```
./sipp -h  # Show help
./sipp -v  # Show build and version information
```
See also the [official reference documentation](https://sipp.sourceforge.net/doc/reference.html).