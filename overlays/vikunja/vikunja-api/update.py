#!/usr/bin/env nix-shell
#!nix-shell -p python3 -p nix-prefetch-git -i python3

import json
import pathlib
import subprocess
import sys

NIL_HASH = 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
MISMATCH_PATTERN = 'hash mismatch in fixed-output derivation'
GOT_PATTERN = ' got: '
EOL_PATTERN = '\n'

def replace_contents(path, process):
    with open(path) as f:
        contents = f.read()

    contents = process(contents)

    with open(path, 'w') as f:
        f.write(contents)

def main():
    current_dir = pathlib.Path(__file__).parent
    src_file = current_dir / 'src.json'
    expr_file = current_dir / 'default.nix'

    with open(src_file) as f:
        original_src_data = json.load(f)

    new_src_contents = subprocess.check_output(['nix-prefetch-git', '--leave-dotGit', original_src_data['url']], encoding='utf-8')

    with open(src_file, 'w') as f:
        f.write(new_src_contents)

    output_hash = json.loads(subprocess.check_output(['nix-instantiate', '--eval', '--json', '-E', f'(((import <nixpkgs> {{}}).callPackage {current_dir} {{}}).go-modules.outputHash)'], encoding='utf-8'))

    replace_contents(expr_file, lambda contents: contents.replace(output_hash, NIL_HASH))

    build_attempt = subprocess.run(['nix-build', '--no-out-link', '-E', f'(((import <nixpkgs> {{}}).callPackage {current_dir} {{}}).go-modules)'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf-8')

    if build_attempt.returncode == 0:
        print('Build succeeded', file=sys.stderr)
        sys.exit(1)
    elif MISMATCH_PATTERN not in build_attempt.stderr:
        print(build_attempt.stderr)
        print('Hash mismatch not found', file=sys.stderr)
        sys.exit(1)
    else:
        mismatch_pos = build_attempt.stderr.rfind(MISMATCH_PATTERN)
        got_pos = build_attempt.stderr.find(GOT_PATTERN, mismatch_pos)
        eol_pos = build_attempt.stderr.find(EOL_PATTERN, got_pos)
        checksum = build_attempt.stderr[got_pos+len(GOT_PATTERN):eol_pos].strip()

        replace_contents(expr_file, lambda contents: contents.replace(NIL_HASH, checksum))

if __name__ == '__main__':
    main()
