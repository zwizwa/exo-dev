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

# Note that multi-line bash variables are not a good idea.  They work
# if bash does the expansion, but GNU Make will not replace the
# newlines with spaces.

set | grep CFLAGS

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

# The 'exo-dev' binary is for tools that are installed via nixos, where the
# version is always up to do.  It is only the raw source repos that have
# raw references to /nix/store to not include a dependency on nix itself.
mkdir -p $out/bin
cat <<EOF >$out/bin/exo-dev
#!/bin/sh
echo $out
EOF
chmod +x $out/bin/exo-dev

ls -l $out
cat $out/env

# set
