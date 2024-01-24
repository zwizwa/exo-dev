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
  inputs = {
    # Old system snapshot. Try to remove this eventually.
    nixpkgs_old.url = github:zwizwa/nixpkgs;
    # New unstable snapshot.
    nixpkgs.url = github:NixOS/nixpkgs/85f1ba3e51676fa8cc604a3d863d729026a6b8eb;

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

  outputs = { self, nixpkgs_old, nixpkgs, libopencm3, rust-overlay }:
    let system = "x86_64-linux";
        pkgs_old = import nixpkgs_old {
          inherit system;
        };
        pkgs = import nixpkgs {
          inherit system;
          overlays =  [ (import rust-overlay) ];
        };
        targets = [
          "thumbv6m-none-eabi"
          "thumbv7m-none-eabi"
          "thumbv7em-none-eabihf"
        ];
        rustToolchain = pkgs.pkgsBuildHost.rust-bin.stable."1.75.0".default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
          inherit targets;
        };
        buildInputs = (with pkgs_old; [
          # FIXME: Is this still needed?
          python
          # C
          gcc-arm-embedded
        ]) ++ (with pkgs; [
          # base deps
          which bash hexdump git socat readline sqlite boehmgc
          # debugging
          openocd
          # C
          gcc clang
          # usb
          libusb libusb-compat-0_1
          # audio
          jack2 a2jmidid alsa-lib puredata
          # rust
          rustToolchain # rustup explicitly not used
          # fpga
          yosys nextpnr
          # zig
          zig
        ]);
    in
  {
    # Old hack to collect buildInputs in env vars.
    packages.${system}.default =
      pkgs.stdenv.mkDerivation {
        name = "exo-dev";
        src = self;
        LIBOPENCM3 = libopencm3.packages.${system}.default;
        inherit buildInputs rustToolchain;
        cToolchain = pkgs.gcc;
        builder = ./builder.sh;
      };

    # New standard flake approach
    devShells.${system}.default =
      pkgs.mkShell {
        packages = buildInputs;
        TPF = "${pkgs.gcc-arm-embedded}/bin/arm-none-eabi-";
        LIBOPENCM3 = libopencm3.packages.${system}.default;
        shellHook = ''
          PS1="(exo-dev) \u@\h:\w\$ "
        '';          
      };
  };
}
