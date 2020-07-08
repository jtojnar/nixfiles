#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=channel:nixos-unstable -p python3 -i python3

from typing import List, Optional
import argparse
import json
import pathlib
import re
import subprocess
import sys

NIL_HASH = 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
MISMATCH_PATTERN = 'hash mismatch in fixed-output derivation'
GOT_PATTERN = ' got: '
EOL_PATTERN = '\n'

def replace_contents(path: pathlib.Path, process):
    with open(path) as f:
        contents = f.read()

    contents = process(contents)

    with open(path, 'w') as f:
        f.write(contents)

def escape(characters_to_escape: str, s: str) -> str:
    return str(f'\\{c}' if c in characters_to_escape else c for c in s)

def escape_nix_string(s: str) -> str:
    return escape('$', json.dumps(s))

def escape_nix_identifier(s: str) -> str:
    # Regex from https://github.com/NixOS/nix/blob/d048577909e383439c2549e849c5c2f2016c997e/src/libexpr/lexer.l#L91
    if re.match(r"[a-zA-Z_][a-zA-Z0-9_'-]*", s) != None:
        return s
    else:
        return escape_nix_string(s)

def attr_path_to_accessor(attr_path: List[str]) -> str:
    return '.'.join([ escape_nix_identifier(attr) for attr in attr_path ])

def get_current_platform() -> str:
    return json.loads(subprocess.check_output(['nix-instantiate', '--eval', '--json', '-E', 'builtins.currentSystem'], encoding='utf-8'))

def get_derivation_attribute(platform: str, attr_path: List[str]):
    return json.loads(subprocess.check_output(['nix-instantiate', '--eval', '--json', '-A', f'outputs.packages.{platform}.{attr_path_to_accessor(attr_path)}'], encoding='utf-8'))

def try_building_attr(platform: str, attr_path: List[str]):
    return subprocess.run(['nix-build', '--no-out-link', '-A', f'outputs.packages.{platform}.{attr_path_to_accessor(attr_path)}'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf-8')

def get_mismatched_checksum(error_output) -> Optional[str]:
    if MISMATCH_PATTERN not in error_output:
        return None
    else:
        mismatch_pos = error_output.rfind(MISMATCH_PATTERN)
        got_pos = error_output.find(GOT_PATTERN, mismatch_pos)
        eol_pos = error_output.find(EOL_PATTERN, got_pos)
        return error_output[got_pos+len(GOT_PATTERN):eol_pos].strip()


def main():
    parser = argparse.ArgumentParser(description='Update Go package')
    parser.add_argument('attr_path', metavar='attr-path', help='Attribute path of package to update')
    args = parser.parse_args()

    current_dir = pathlib.Path(__file__).parent
    expr_file = (current_dir / 'default.nix').absolute()

    platform = get_current_platform()
    package_path = args.attr_path

    # Obtain all the required data from the expression: URL, old commit and the checksums of src and go-modules.
    repo_url = get_derivation_attribute(platform, [package_path, 'src', 'url'])
    previous_rev = get_derivation_attribute(platform, [package_path, 'src', 'rev'])
    src_hash = get_derivation_attribute(platform, [package_path, 'src', 'outputHash'])
    go_deps_hash = get_derivation_attribute(platform, [package_path, 'go-modules', 'outputHash'])

    # Find the latest upstream commit.
    remote_refs = subprocess.check_output(['git', 'ls-remote', repo_url, 'HEAD'], encoding='utf-8')
    latest_commit, ref_name = remote_refs.split()
    assert ref_name == 'HEAD'

    # Update the commit in the expression and set nil hash for TOFU.
    replace_contents(expr_file, lambda contents: contents.replace(previous_rev, latest_commit).replace(src_hash, NIL_HASH))

    # Get the checksum for the new src and replace it in the expression.
    src_build_attempt = try_building_attr(platform, [package_path, 'src'])
    if src_build_attempt.returncode == 0:
        print('Building src succeeded', file=sys.stderr)
        sys.exit(1)
    else:
        checksum = get_mismatched_checksum(src_build_attempt.stderr)
        if checksum:
            replace_contents(expr_file, lambda contents: contents.replace(NIL_HASH, checksum))
        else:
            print(src_build_attempt.stderr, file=sys.stderr)
            print('Hash mismatch not found', file=sys.stderr)
            sys.exit(1)

    # Set nil hash for go-modules TOFU.
    replace_contents(expr_file, lambda contents: contents.replace(go_deps_hash, NIL_HASH))

    # Get the checksum for the new go-modules and replace it in the expression.
    go_deps_build_attempt = try_building_attr(platform, [package_path, 'go-modules'])
    if go_deps_build_attempt.returncode == 0:
        print('Building go-modules succeeded', file=sys.stderr)
        sys.exit(1)
    else:
        checksum = get_mismatched_checksum(go_deps_build_attempt.stderr)
        if checksum:
            replace_contents(expr_file, lambda contents: contents.replace(NIL_HASH, checksum))
        else:
            print(go_deps_build_attempt.stderr, file=sys.stderr)
            print('Hash mismatch not found', file=sys.stderr)
            sys.exit(1)

if __name__ == '__main__':
    main()
