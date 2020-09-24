#!/bin/zsh -e

# Assumes gh is installed and logged in

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ ! "$BRANCH" = "master" ]; then
	printf >&2 "\033[1;31mNot on master branch, abording\033[0m"
	exit 255
fi

if  [[ -n $(git status --porcelain) ]]; then
  printf >&2 "\033[1;31mCannot release version because there are unstaged changes, aborting\nChanges:\033[0m\n"
  git status --short
  exit 255
fi

if [[ -n $(git log --branches --not --remotes) ]]; then
  echo -e "\033[1;34mPushing pending commits to git\033[0m"
  git push
fi

echo -e "\033[1;34mCreating release notes\033[0m"

RELEASE_NOTES_FILE="${SCRIPTPATH}/Distribution/_tmp_release_notes.md"

touch "${RELEASE_NOTES_FILE}"
open -Wn "${RELEASE_NOTES_FILE}"

if ! [ -s "${RELEASE_NOTES_FILE}" ]; then
	echo -e >&2 "\033[1;31mNo release notes provided, aborting\033[0m"
	rm -f "${RELEASE_NOTES_FILE}"
	exit 255
fi

"${SCRIPTPATH}/Scripts/updateCopyright.sh"

"${SCRIPTPATH}/build.sh"

echo -e "\033[1;34mCopying script\033[0m"
cp "${SCRIPTPATH}/record.sh" "${SCRIPTPATH}/Distribution"

echo -e "\033[1;34mUpdating package.json version\033[0m"
SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${SCRIPTPATH}/Distribution/DetoxRecorder.framework/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${SCRIPTPATH}/Distribution/DetoxRecorder.framework/Info.plist")

VERSION="${SHORT_VERSION}"."${BUILD_NUMBER}"

cd "${SCRIPTPATH}/Distribution"
npm version "${VERSION}" --allow-same-version

# echo -e "\033[1;34mReleasing\033[0m"
npm publish

git add -A &> /dev/null
git commit -m "${VERSION}" &> /dev/null
git push

echo -e "\033[1;34mCreating GitHub release\033[0m"

gh release create --repo wix/DetoxRecorder "$VERSION" --title "$VERSION" --notes-file "${RELEASE_NOTES_FILE}"

rm -f "${RELEASE_NOTES_FILE}"