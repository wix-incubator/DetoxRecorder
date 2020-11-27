#!/bin/zsh -e
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# rm -fr "${SCRIPTPATH}/Build"
rm -fr "${SCRIPTPATH}/Distribution/DetoxRecorder.framework"
rm -f "${SCRIPTPATH}/Distribution/DetoxRecorderCLI"
rm -rf "${SCRIPTPATH}/Distribution/Source"

echo -e "\033[1;34mBuilding DetoxRecorder.framework\033[0m"

xcodebuild -project "${SCRIPTPATH}/DetoxRecorder/DetoxRecorder.xcodeproj" build -configuration Release -scheme DetoxRecorder -destination 'generic/platform=iOS Simulator' -derivedDataPath "${SCRIPTPATH}/Build" -quiet
cp -R "${SCRIPTPATH}/Build/Build/Products/Release-iphonesimulator/DetoxRecorder.framework" "${SCRIPTPATH}/Distribution"

echo -e "\033[1;34mBuilding Detox Recorder CLI\033[0m"

xcodebuild -project "${SCRIPTPATH}/DetoxRecorder/DetoxRecorder.xcodeproj" build -configuration Release -scheme DetoxRecorderCLI -sdk macosx -derivedDataPath "${SCRIPTPATH}/Build" -quiet
cp "${SCRIPTPATH}/Build/Build/Products/Release/DetoxRecorderCLI" "${SCRIPTPATH}/Distribution"

echo -e "\033[1;34mCopying sources\033[0m"
mkdir -p "${SCRIPTPATH}/Distribution/Source"
cp -R "${SCRIPTPATH}/DetoxRecorder" "${SCRIPTPATH}/Distribution/Source"