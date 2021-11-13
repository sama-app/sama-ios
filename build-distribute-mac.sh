#/bin/bash
set -e

archivePath='sama.xcarchive'
buildPath='build-sama'

# clean
rm -rf $buildPath
rm -rf $archivePath

# build and archive
set -o pipefail && \
 xcodebuild \
 -project sama.xcodeproj \
 -scheme sama-mac \
 -configuration Release \
 -archivePath $archivePath \
 archive CODE_SIGN_STYLE=Manual \
 | xcpretty
