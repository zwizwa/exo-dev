#!/bin/sh
cd $(dirname "$0")
exec nix develop --command make -C /i/exo/synth_tools "$@"

