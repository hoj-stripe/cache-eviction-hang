#!/usr/bin/env bash

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m | tr '[:upper:]' '[:lower:]')"

export BAZEL_REMOTE_SHA_darwin_x86_64="555ae6076bf0d76516ecc5b7b1b64310642b6268b30601bccaa686bda89bb93c"
export BAZEL_REMOTE_SHA_darwin_arm64="7ceb05ff3014c8517fd4eb38ba18763fb20b0aa5400ec72f2f4b0b7dc1a9b73c"
export BAZEL_REMOTE_SHA_linux_x86_64="5e4b248262a56e389e9ee4212ffd0498746347fb5bf155785c9410ba2abc7b07"
export BAZEL_REMOTE_SHA_linux_arm64=""

VERSION="2.4.3"
url="https://github.com/buchgr/bazel-remote/releases/download/v${VERSION}/bazel-remote-${VERSION}-${platform}-${arch}"

mkdir -p .cache

BAZEL_REMOTE=".cache/bazel-remote"
if [[ -f "$BAZEL_REMOTE" ]]; then
    sha256=$(shasum -a256 "$BAZEL_REMOTE" | cut -d' ' -f1)
    expected_name="BAZEL_REMOTE_SHA_${platform}_${arch}"
    if [[ "$sha256" != "${!expected_name}" ]]; then
        echo "SHA mismatch on ${BAZEL_REMOTE}! removing it: expected ${!expected_name} but got $sha256"
        rm "$BAZEL_REMOTE"
    fi
fi

if [[ ! -f "$BAZEL_REMOTE" ]]; then
    wget "$url" -O "$BAZEL_REMOTE"
    chmod +x "$BAZEL_REMOTE"
fi

sha256=$(shasum -a256 "$BAZEL_REMOTE" | cut -d' ' -f1)
expected_name="BAZEL_REMOTE_SHA_${platform}_${arch}"
if [[ "$sha256" != "${!expected_name}" ]]; then
    echo "SHA mismatch on ${BAZEL_REMOTE}! expected ${!expected_name} but got $sha256"
    exit 1
fi

CACHE_DIR=$(mktemp -d)

$BAZEL_REMOTE --dir "$CACHE_DIR" --max_size 1 &
BAZEL_REMOTE_PID=$!

function cleanup {
    kill $BAZEL_REMOTE_PID
    if [[ -d "$CACHE_DIR" ]]; then
        echo "Run rm -rf \"$CACHE_DIR\" to clean up"
    fi
}

sleep 1

trap cleanup EXIT

bazel clean --expunge

# build all the dependencies to populate the inputs in the cache
bazel build //... --remote_cache=grpc://localhost:9092
bazel_exit=$?
echo "Bazel exited with ${bazel_exit}"

# shut down the remote cache to clear out in-memory state, to simulate cache eviction
kill $BAZEL_REMOTE_PID

sleep 1

printf "\n\n"
echo "Removing the cache objects to simulate cache eviction..."
find "$CACHE_DIR/" -type f -delete

# Restart the remote cache with fresh memory.
$BAZEL_REMOTE --dir "$CACHE_DIR" --max_size 1 &
BAZEL_REMOTE_PID=$!

printf "\n\n"

sleep 1

# Rerun with remote execution to trigger failure with exit code 34 on a new
# output base to avoid reusing persistent action cache, simulating a Bazel
# invocation in a different machine
workdir=$(mktemp -d -p /tmp)
bazel --output_base="$workdir" build //:all_files --remote_cache=grpc://localhost:9092 --remote_executor=grpc://localhost:8980
bazel_exit=$?
echo "Bazel exited with ${bazel_exit}"

printf "\n\n"
