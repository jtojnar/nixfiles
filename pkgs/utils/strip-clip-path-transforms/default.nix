{
  writeShellScriptBin,
  lib,
  coreutils,
  libxslt,
}:

# Taken from https://gitlab.com/inkscape/inkscape/-/issues/791#note_584055227
writeShellScriptBin "strip-clip-path-transforms" ''
  PATH=${
    lib.makeBinPath [
      coreutils # for mktemp
      libxslt # for xsltproc
    ]
  }
  for file in "$@"; do
      tempfile=$(mktemp)
      xsltproc "${./fix-clip-path.xsl}" "$file" > "$tempfile"
      xsltproc "${./remove-transform-attr.xsl}" "$tempfile" > "$file"
      rm "$tempfile"
  done
''
