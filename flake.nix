# A Nix Flake wrapper for the dev tools used to build all zwizwa exo
# projects (uc_tools, synth_tools, rs_tools, ...)

# This supports:
#
# - Building on nix systems.  Use "nix develop --command" to run make
#   on an external source tree.  See the make*.sh scripts in this
#   directory.
#
# - Building on non-nix systems: The result produced by "nix build"
#   will provide a derivation called "exo-dev" that contains an env
#   script that can be used on non-nix hosts by copying the closure to
#   /nix/store.  This old approach is deprecated but kept alive for
#   now for backwards compatibility.

{
  description = "Build dependencies for exo projects";
  # inputs.nixpkgs.url = github:NixOS/nixpkgs/85f1ba3e51676fa8cc604a3d863d729026a6b8eb; # Unstable snapshot.
  inputs = {
    nixpkgs.url = github:zwizwa/nixpkgs;

    # This is split off so it doesn't need to be rebuilt when exo-dev
    # dependencies change.
    libopencm3.url = github:zwizwa/libopencm3-flake;

    # Wrapper for binary distribution implemented as a nixpkgs overlay.
    # https://github.com/oxalica/rust-overlay/blob/master/docs/reference.md
    # https://github.com/oxalica/rust-overlay/blob/master/README.md
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      # url = "git+file:///i/tom/git/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, libopencm3, rust-overlay }:
    let system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          overlays =  [ (import rust-overlay) ];
        };
        targets = [ "thumbv7m-none-eabi" ];
        rustToolchain = pkgs.pkgsBuildHost.rust-bin.stable.latest.default.override {
          inherit targets;
        };

        #  toolchain = pkgs.rustChannels.stable;
        # rustc = toolchain.rust.override { inherit targets; }
        # rustPlatform = pkgs.recurseIntoAttrs (pkgs.makeRustPlatform {
        #   rustc = rustc;
        #   cargo = toolchain.cargo;
        # });
    in
  {
    packages.${system}.default =
      with import nixpkgs { inherit system; };
      stdenv.mkDerivation {
        name = "exo-dev";
        buildInputs = with pkgs; [
          gcc gcc-arm-embedded
          which bash hexdump git
          openocd python socat readline sqlite boehmgc
          libusb libusb-compat-0_1
          jack2 a2jmidid alsa-lib puredata
          rustToolchain
          # rustup
          # unstable.zig
        ];
        src = self;
        LIBOPENCM3 = libopencm3.packages.${system}.default;
        builder = ./builder.sh;
      };
  };
}
