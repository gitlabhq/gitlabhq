#!/bin/bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <Sidekiq version> <vendored gem directory>"
    echo ""
    echo "Example: $0 7.3.1 /path/to/gdk/gitlab/vendor/gems/sidekiq"
    exit 1
fi

VERSION=$1
TARGET_DIR=$2
TEMP_DIR=$(mktemp -d)
GEM_DIR=sidekiq-$VERSION
GIT_REPO=https://github.com/sidekiq/sidekiq
PATCH_DIR=$(realpath "$TARGET_DIR/patches")

pushd . > /dev/null
# Unpack gem
cd "$TEMP_DIR"
echo "Unpacking sidekiq gem $VERSION..."
gem unpack sidekiq -v "$VERSION"
echo "Cloning $GIT_REPO..."
git clone --depth 1 -b "v$VERSION" https://github.com/sidekiq/sidekiq.git sidekiq.git
cd "$GEM_DIR"
cp -r ../sidekiq.git/test .

echo "Applying GitLab patches..."
for patch in "$PATCH_DIR"/*.patch; do
    echo "Applying $patch"
    patch -p1 < "$patch"
done

echo "Copying updated Sidekiq files from $TEMP_DIR/$GEM_DIR into $TARGET_DIR"
popd > /dev/null
cp -r "$TEMP_DIR/$GEM_DIR"/* "$TARGET_DIR"
rm -rf "$TEMP_DIR"

bundle install

echo "Update complete! You can now:"
echo ""
echo "1. Inspect the differences via 'git diff'".
echo "2. Run tests locally by running 'redis-server' and 'bundle exec rake test'."
echo "3. Update NOTICE.txt to refelct the current date."
