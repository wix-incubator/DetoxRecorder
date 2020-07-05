#!/bin/zsh
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
CLI="${SCRIPTPATH}/DetoxRecorderCLI"

#Forward all arguments to CLI tool
"${CLI}" "$@"