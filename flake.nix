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

    # See https://wiki.nixos.org/wiki/ESP-IDF
    # I'm using the "manual install" procedure below.
    # esp32-idf.url = github:mirrexagon/nixpkgs-esp-dev; #esp32-idf;

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
        haskell = pkgs.haskellPackages.ghcWithPackages (pkgs: with pkgs; [
          cabal-install
          ghcid
        ]);

        pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [
          # esphome
        ]);

        fhsEnv = pkgs.buildFHSUserEnv {
          name = "esp32-toolchain-env";
          targetPkgs = pkgs: with pkgs; [ zlib ];
          runScript = "";
        };

        esp32 = pkgs.stdenv.mkDerivation rec {
          pname = "esp32-toolchain";

          version = "2021r2-patch3";
          # version = "13.2.0_20240530";

          src = pkgs.fetchurl {
            # url = "https://github.com/espressif/crosstool-NG/releases/download/esp-${version}/riscv32-esp-elf-gcc8_4_0-esp-${version}-linux-amd64.tar.gz";
            # hash = "sha256-F5y61Xl5CtNeD0FKGNkAF8DxWMOXAiQRqOmGfbIXTxU=";

            url = "https://github.com/espressif/crosstool-NG/releases/download/esp-${version}/xtensa-esp32-elf-gcc8_4_0-esp-${version}-linux-amd64.tar.gz";
            hash = "sha256-nt0ed2J2iPQ1Vhki0UKZ9qACG6H2/2fkcuEQhpWmnlM=";  # 2021r2-patch3

          };

          buildInputs = [ pkgs.makeWrapper ];

          phases = [ "unpackPhase" "installPhase" ];

          installPhase = ''
            cp -r . $out
            for FILE in $(ls $out/bin); do
              FILE_PATH="$out/bin/$FILE"
              if [[ -x $FILE_PATH ]]; then
                mv $FILE_PATH $FILE_PATH-unwrapped
                makeWrapper ${fhsEnv}/bin/esp32-toolchain-env $FILE_PATH --add-flags "$FILE_PATH-unwrapped"
              fi
            done      
          '';

          meta = with pkgs.lib; {
            description = "ESP32 toolchain";
            homepage = https://docs.espressif.com/projects/esp-idf/en/stable/get-started/linux-setup.html;
            license = licenses.gpl3;
          };
        };

        buildInputs = (with pkgs_old; [
          # Pyton
          pythonWithPackages
          # C
          gcc-arm-embedded
          # ESP
          esp32
        ]) ++ (with pkgs; [
          # base deps
          which bash hexdump git socat readline sqlite boehmgc
          # debugging
          openocd
          # C
          gcc clang pkg-config clang-tools
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
          # haskell
          haskell
          # racket
          racket
          # accounting
          hledger hledger-ui
     
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
        racket = pkgs.racket;
        # FIXME: Create a bin directory with all pacakges and link it.
        # This makes it easier to link everything into ~/.emacs.d/bin
        # as well.
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
