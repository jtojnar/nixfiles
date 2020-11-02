#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=channel:nixos-unstable -p python3 -p nix -i python3

from typing import List, Optional
import argparse
import json
import pathlib
import re
import subprocess
import sys
import urllib.request

NIL_HASH = 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='

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

def get_url_contents(url: str) -> str:
    response = urllib.request.urlopen(url)
    contents = response.read()
    return contents.decode('utf-8') 

def main():
    parser = argparse.ArgumentParser(description='Update package')
    parser.add_argument('attr_path', metavar='attr-path', help='Attribute path of package to update')
    args = parser.parse_args()

    current_dir = pathlib.Path(__file__).parent
    expr_file = (current_dir / 'packages.nix').absolute()

    platform = get_current_platform()
    package_path = args.attr_path

    # Obtain all the required data from the expression: URL, old version, commit and the checksums of src and go-modules.
    previous_version = str(get_derivation_attribute(platform, [package_path, 'version']))
    latest_version = str(json.loads(get_url_contents('https://www.sublimetext.com/updates/4/dev_update_check'))['latest_version'])
    if latest_version == previous_version:
        print('The new version same as the old version.', file=sys.stderr)
        sys.exit(0)

    # Update the version.
    replace_contents(expr_file, lambda contents: contents.replace(previous_version, latest_version))

    platforms = get_derivation_attribute(platform, [package_path, 'meta', 'platforms'])
    for platform in platforms:
        src_hash = get_derivation_attribute(platform, [package_path, 'sublime_text', 'src', 'outputHash'])

        # Set nil hash for TOFU.
        replace_contents(expr_file, lambda contents: contents.replace(src_hash, NIL_HASH))

        download_url = get_derivation_attribute(platform, [package_path, 'sublime_text', 'src', 'urls'])[0]
        fetch_source_attempt = subprocess.run(['nix-prefetch-url', '--type', 'sha256', download_url], stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf-8')

        if fetch_source_attempt.returncode == 0:
            checksum = fetch_source_attempt.stdout.strip()
            replace_contents(expr_file, lambda contents: contents.replace(NIL_HASH, checksum))
        else:
            print('Failed to get checksum', file=sys.stderr)
            sys.exit(1)

if __name__ == '__main__':
    main()
