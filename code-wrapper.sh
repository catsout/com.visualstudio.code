#!/bin/bash

set -e
shopt -s nullglob

function msg() {
  echo "flatpak-vscode: $*" >&2
}

PYTHON_SITEDIR=$(python3 <<EOFPYTHON
import os
import site
print(os.path.relpath(site.getusersitepackages(), site.getuserbase()))
EOFPYTHON
)

for tool_dir in /app/tools/*; do
  tool_bindir=$tool_dir/bin
  if [ -d "$tool_bindir" ]; then
    msg "Adding $tool_bindir to PATH"
    export PATH=$PATH:$tool_bindir
  fi
  tool_pythondir=$tool_dir/$PYTHON_SITEDIR
  if [ -d "$tool_pythondir" ]; then
    msg "Adding $tool_pythondir to PYTHONPATH"
    if [ -z "$PYTHONPATH" ]; then
      export PYTHONPATH=$tool_pythondir
    else
      export PYTHONPATH=$PYTHONPATH:$tool_pythondir
    fi
  fi
done

if [ "$FLATPAK_ENABLE_SDK_EXT" = "*" ]; then
  SDK=()
  for d in /usr/lib/sdk/*; do
    SDK+=("${d##*/}")
  done
else
  IFS=',' read -ra SDK <<< "$FLATPAK_ENABLE_SDK_EXT"
fi

for i in "${SDK[@]}"; do
  if [[ -d /usr/lib/sdk/$i ]]; then
    msg "Enabling SDK extension \"$i\""
    if [[ -f /usr/lib/sdk/$i/enable.sh ]]; then
      . /usr/lib/sdk/$i/enable.sh
    else
      export PATH=$PATH:/usr/lib/sdk/$i/bin
    fi
  else
    msg "Requested SDK extension \"$i\" is not installed"
  fi
done

export PATH="${PATH}:${XDG_DATA_HOME}/node_modules/bin" 

exec /app/bin/zypak-wrapper /app/extra/vscode/code "$@"