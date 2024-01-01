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
  inputs.nixpkgs.url = github:zwizwa/nixpkgs;

  outputs = { self, nixpkgs }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
  {
    packages.x86_64-linux.default =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "exo-dev";
        buildInputs = with pkgs; [
          gcc gcc-arm-embedded
          which bash hexdump git
          openocd python socat readline sqlite boehmgc
          libusb libusb-compat-0_1
          jack2 a2jmidid alsa-lib puredata
          # rustup
          # unstable.zig
        ];
        src = self;
        builder = ./builder.sh;
      };
  };
}
