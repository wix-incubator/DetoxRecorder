#!/bin/zsh
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
rm -fr "${SCRIPTPATH}/Build"
xcodebuild -project "${SCRIPTPATH}/DetoxRecorder/DetoxRecorder.xcodeproj" clean build -configuration Release -scheme DetoxRecorderFramework -derivedDataPath "${SCRIPTPATH}/Build" -quiet
cp -R "${SCRIPTPATH}/Build/Build/Products/Release-universal/DetoxRecorder.framework" "${SCRIPTPATH}/Build"

xcodebuild -project "${SCRIPTPATH}/DetoxRecorder/DetoxRecorder.xcodeproj" clean build -configuration Release -scheme DetoxRecorderCLI -sdk macosx -derivedDataPath "${SCRIPTPATH}/Build" -quiet
cp "${SCRIPTPATH}/Build/Build/Products/Release/DetoxRecorderCLI" "${SCRIPTPATH}/Build"