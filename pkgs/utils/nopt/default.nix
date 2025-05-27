{
  writeShellScriptBin,
  nixos-option,
}:

writeShellScriptBin "nopt" ''
  if [[ ! -f $PWD/flake.nix ]]; then
    echo "nopt: Must be run in flake root."
    exit 1
  fi

  if [[ "$1" = "-h" || "$1" = "--hostname" ]]; then
    shift
    hostname=$1
    shift
  else
    hostname=$(cat /etc/hostname)
  fi

  if (( $# < 1 )); then
    echo "Usage: nopt [option…]"
    exit 1
  fi

  ${nixos-option}/bin/nixos-option --flake .#$hostname "$@"
''
