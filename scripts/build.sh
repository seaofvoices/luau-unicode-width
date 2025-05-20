#!/bin/sh

set -e

scripts/build-single-file.sh .darklua-bundle.json build/unicode-width.luau
scripts/build-roblox-model.sh .darklua.json build/unicode-width.rbxm
