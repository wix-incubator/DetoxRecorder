#!/bin/zsh
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
CLI="${SCRIPTPATH}/Build/DetoxRecorderCLI"
FRAMEWORK_BINARY="${SCRIPTPATH}/Build/DetoxRecorder.framework/DetoxRecorder"

if [ ! -f "${FRAMEWORK_BINARY}" ] || [ ! -f "${CLI}" ]; then
	${SCRIPTPATH}/build.sh &> /dev/null
fi

if [ ! -f "${FRAMEWORK_BINARY}" ]; then
	echo "Error: unable to build framework"
	exit -1
fi

#Forward all arguments to CLI tool
"${CLI}" "$@"