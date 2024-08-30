#!/bin/bash
set -e

docker run --rm --privileged \
  multiarch/qemu-user-static \
  --reset -p yes

# Build for AMD64
docker build . -f Dockerfile.static -t sixteen-builder
docker run -ti --rm -v "$PWD":/app --user="$UID" sixteen-builder /bin/sh -c "cd /app && rm -rf lib shard.lock && shards build --static"
mv bin/sixteen bin/sixteen-static-linux-amd64

# Build for ARM64
docker build . -f Dockerfile.static --platform linux/arm64 -t sixteen-builder
docker run -ti --rm -v "$PWD":/app --platform linux/arm64 --user="$UID" sixteen-builder /bin/sh -c "cd /app && rm -rf lib shard.lock && shards build --static"
mv bin/sixteen bin/sixteen-static-linux-arm64
