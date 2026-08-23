#!/bin/bash
set -e

# Cross-compiles object files natively on the host, then statically links
# each architecture inside a minimal Alpine container. The Crystal compiler
# never runs under emulation; only the fast final link step does.
#
# NOTE: the linker image provides the C libraries the object files expect.
# Host Crystal >= 1.21 requires libxml2 >= 2.13 (Alpine >= 3.22).

mkdir -p build bin
rm -f bin/sixteen-static-linux-amd64 bin/sixteen-static-linux-arm64

shards install

echo "==> Cross-compiling x86_64 object file"
crystal build src/main.cr --release --static --cross-compile \
  --target x86_64-linux-musl -o build/sixteen-x86_64.o

echo "==> Cross-compiling aarch64 object file"
crystal build src/main.cr --release --static --cross-compile \
  --target aarch64-linux-musl -o build/sixteen-aarch64.o

echo "==> Building linker images"
docker build -q . -f Dockerfile.link --platform linux/amd64 -t sixteen-linker-amd64
docker build -q . -f Dockerfile.link --platform linux/arm64 -t sixteen-linker-arm64

LINK_FLAGS="-static -rdynamic -lgc -lpcre2-8 -lyaml -lxml2 -lz -llzma -lpthread -ldl -lm"

echo "==> Statically linking amd64 binary"
docker run --rm -v "$PWD":/app --user="$(id -u)" sixteen-linker-amd64 \
  sh -c "cd /app && cc build/sixteen-x86_64.o -o bin/sixteen-static-linux-amd64 $LINK_FLAGS && strip bin/sixteen-static-linux-amd64"

echo "==> Statically linking arm64 binary"
docker run --rm --platform linux/arm64 -v "$PWD":/app --user="$(id -u)" sixteen-linker-arm64 \
  sh -c "cd /app && cc build/sixteen-aarch64.o -o bin/sixteen-static-linux-arm64 $LINK_FLAGS && strip bin/sixteen-static-linux-arm64"

echo "==> Done"
ls -la bin/sixteen-static-linux-*
