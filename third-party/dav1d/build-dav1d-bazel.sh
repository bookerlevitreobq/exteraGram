#!/bin/sh

set -e

ARCH="$1"

BUILD_DIR="$2"

MESON_OPTIONS="--buildtype=release --default-library=static -Denable_tools=false -Denable_tests=false"
CROSSFILE=""

if [ "$ARCH" = "arm64" ]; then
    CROSSFILE="../package/crossfiles/arm64-iPhoneOS.meson"
elif [ "$ARCH" = "sim_arm64" ]; then
    rm -f "arm64-iPhoneSimulator-custom.meson"
    TARGET_CROSSFILE="$BUILD_DIR/dav1d/package/crossfiles/arm64-iPhoneSimulator-custom.meson"
    cp "$BUILD_DIR/arm64-iPhoneSimulator.meson" "$TARGET_CROSSFILE"
    custom_xcode_path="$(xcode-select -p)/"
    sed -i '' "s|/Applications/Xcode.app/Contents/Developer/|$custom_xcode_path|g" "$TARGET_CROSSFILE"
    CROSSFILE="../package/crossfiles/arm64-iPhoneSimulator-custom.meson"
else
    echo "Unsupported architecture $ARCH"
    exit 1
fi

pushd "$BUILD_DIR/dav1d"
rm -rf build
mkdir build
pushd build

cat > ../include/meson.build <<'EOF'
# Revision file (vcs_version.h) generation
vcs_cdata = configuration_data()
vcs_cdata.set('VCS_TAG', meson.project_version())
rev_target = configure_file(
    input: 'vcs_version.h.in',
    output: 'vcs_version.h',
    configuration: vcs_cdata,
)

subdir('dav1d')
EOF

meson.py setup .. --cross-file="$CROSSFILE" $MESON_OPTIONS
ninja

popd
popd

