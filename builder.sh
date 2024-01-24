#!/bin/sh
source $stdenv/setup

# All build products go here
echo "out=$out"
mkdir -p $out

# This script runs in a temporary directory that is deleted after
# building.
echo "pwd=$(pwd)"

# Keys defined as derivation attributes in generic.nix which show up
# as variables here, containing the /nix/store paths where the sources
# are extracted.
echo "src=$src"

# Convert PATH, NIX_LDFLAGS and NIX_CFLAGS_COMPILE to EXO_DEV_
# variables that can be used in a build script to reconstruct PATH,
# LDFLAGS and CFLAGS.  Perform some formatting to make the env file
# easier to read.  You do not need this file when you are using "nix
# develop".
#
# Note that multi-line bash variables are not a good idea.  They work
# if bash does the expansion, but GNU Make will not replace the
# newlines with spaces.
cat <<EOF >$out/env
EXO_DEV_PATH=\\
${out}/bin:\\
$(echo $PATH | sed s/\:/:\\\\\\n/g)
EXO_DEV_LDFLAGS="\\
$(echo $NIX_LDFLAGS | sed s/-rpath\ /-Wl,-rpath,/g | sed s/\ /\ \\\\\\n/g)"
EXO_DEV_CFLAGS="$(echo $NIX_CFLAGS_COMPILE | sed s/-isystem/\\\\\\n-isystem/g)"
EOF

# NIX_LDFLAGS contains references to these so make sure they are there.
mkdir -p $out/lib64
mkdir -p $out/lib

# The 'exo-dev' prints the location of the repository.  Useful when
# this package is installed.
mkdir -p $out/bin
cat <<EOF >$out/bin/exo-dev
#!/bin/sh
echo $out
EOF
chmod +x $out/bin/exo-dev

# The build inputs are also linked directly.  This allows
# e.g. ~/.emacs.d/rust-toolchain to refer to
# ~/exo/exo-dev/result/rust-toolchain.
(cd $out
ln -s ${rustToolchain} rust-toolchain
ln -s ${cToolchain} c-toolchain
)

ls -l $out
cat $out/env

# set
