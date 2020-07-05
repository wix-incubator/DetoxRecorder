#!/bin/zsh
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
CLI="${SCRIPTPATH}/DetoxRecorderCLI"

codesign -fs - "${CLI}"