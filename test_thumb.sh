#!/bin/sh
RUSTC=rustc
# RUSTC=/nix/store/a6arsybdmg4x20j5zmkfdc0lr104rqbk-rust-default-1.75.0/bin/rustc
$RUSTC test_thumb.rs --target=thumbv7m-none-eabi
