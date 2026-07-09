#!/bin/bash
# Build script for SIPp on macOS ARM (Apple Silicon)
# This script builds SIPp, copies the binary to ./binaries/MacOS ARM,
# and removes all build artifacts.

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BINARY_DIR="./binaries/MacOS ARM"
OPENSSL_PATH="/opt/homebrew/opt/openssl@3.6"

echo "===================================="
echo "Building SIPp for macOS ARM"
echo "===================================="

# Check if OpenSSL is available
if [ ! -d "$OPENSSL_PATH" ]; then
    echo "Error: OpenSSL not found at $OPENSSL_PATH"
    echo "Install with: brew install openssl@3.6"
    exit 1
fi

# Step 1: Generate configure script
echo ""
echo "Step 1: Generating build system..."
autoreconf -ivf

# Step 2: Configure
echo ""
echo "Step 2: Configuring build..."
./configure \
    --with-openssl \
    --with-pcap \
    CPPFLAGS="-I${OPENSSL_PATH}/include" \
    LDFLAGS="-L${OPENSSL_PATH}/lib"

# Step 3: Build
echo ""
echo "Step 3: Building SIPp..."
make -j$(sysctl -n hw.ncpu)

# Step 4: Copy binary
echo ""
echo "Step 4: Copying binary to ${BINARY_DIR}..."
mkdir -p "$BINARY_DIR"
cp sipp "$BINARY_DIR/sipp"
chmod +x "$BINARY_DIR/sipp"

# Get version info
VERSION_INFO=$(./sipp -v 2>&1 | head -1 || echo "SIPp")
echo "Binary copied: ${VERSION_INFO}"

# Step 5: Clean up build artifacts
echo ""
echo "Step 5: Cleaning build artifacts..."
# Save the sipp binary temporarily before make clean removes it
cp sipp sipp.tmp
make clean
rm -f *.o
rm -f sipp_unittest
# Restore the sipp binary
mv sipp.tmp sipp
chmod +x sipp
rm -f .deps/*.Po .deps/*.Tpo
rm -f config.log config.status
rm -f Makefile Makefile.in
rm -f include/config.h include/stamp-h1
rm -rf autom4te.cache
rm -f aclocal.m4 compile configure depcomp install-sh missing test-driver
rm -f config.guess~ config.sub~

echo ""
echo "===================================="
echo "Build complete!"
echo "Binary location: ${BINARY_DIR}/sipp"
echo "===================================="
echo ""
echo "To run SIPp:"
echo "  ${BINARY_DIR}/sipp -h"
