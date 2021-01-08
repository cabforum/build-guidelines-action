#!/bin/bash

set -euo pipefail

stdbuf -i0 -o0 -e0 /cabforum/build.sh "$@"
