#!/bin/bash

set -e

pushd /opt/moongen && make build && popd
pushd /opt/netbricks && make build && popd
mount -t debugfs none /sys/kernel/debug/

exec "$@"
