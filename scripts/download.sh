#!/bin/bash
set -e

VERSION=$1
TARGETARCH=$2
TARGETVARIANT=$3

if [ -z "$VERSION" ]; then
  echo "Version is required"
  exit 1
fi

ARCH=""
case $TARGETARCH in
  "amd64")
    ARCH="x86_64"
    ;;
  "arm64")
    ARCH="aarch64"
    ;;
  "arm")
    if [ "$TARGETVARIANT" = "v7" ]; then
      ARCH="armv7"
    else
      ARCH="arm"
    fi
    ;;
  *)
    echo "Unsupported architecture: $TARGETARCH"
    exit 1
    ;;
esac

echo "Downloading EasyTier $VERSION for $ARCH..."
# URL pattern: https://github.com/EasyTier/EasyTier/releases/download/v2.4.5/easytier-linux-x86_64-v2.4.5.zip
URL="https://github.com/EasyTier/EasyTier/releases/download/${VERSION}/easytier-linux-${ARCH}-${VERSION}.zip"

echo "URL: $URL"
curl -L -o easytier.zip "$URL"
unzip easytier.zip
# The zip usually contains a folder named easytier-linux-<ARCH>
# But sometimes it might be different or flat. The install script assumes:
# mv $INSTALL_PATH/easytier-linux-${ARCH}/* $INSTALL_PATH/
# So it extracts to a folder.

if [ -d "easytier-linux-${ARCH}" ]; then
    mv easytier-linux-${ARCH}/* /usr/local/bin/
    rm -rf easytier-linux-${ARCH}
else
    # Fallback if structure is different, list files
    echo "Unexpected zip structure. Listing files:"
    ls -R
    exit 1
fi

rm easytier.zip
chmod +x /usr/local/bin/easytier-core /usr/local/bin/easytier-cli
if [ -f /usr/local/bin/easytier-web-embed ]; then
    chmod +x /usr/local/bin/easytier-web-embed
fi
