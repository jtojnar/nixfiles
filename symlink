#!/usr/bin/env bash

HOST=`hostname`
if [[ ! -z "$1" ]]; then
	HOST=$1
fi

if [[ ! -e "hosts/$HOST/configuration.nix" ]] || [[ ! -e "hosts/$HOST/hardware-configuration.nix" ]]; then
	echo "missing $HOST.nix or $HOST-hardware.nix" >&2
	exit 1
fi

ln -f "hosts/$HOST/configuration.nix" .
ln -f "hosts/$HOST/hardware-configuration.nix" .
