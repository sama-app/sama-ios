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
set -o pipefail && \
 xcodebuild -exportArchive \
 -archivePath $archivePath \
 -exportOptionsPlist $EXPORT_OPTIONS_PLIST \
 -exportPath $buildPath \
 | xcpretty

echo "finish export"

# notarize

appPath="$buildPath/Sama.app"
appPreNotarizationZipPath="$buildPath/Sama-pre-notarization.zip"
appZipPath="$buildPath/Sama.zip"
notarizationRequestPath="$buildPath/notarization-request.plist"
notarizationResultPath="$buildPath/notarization-result.plist"

echo "zip pre notarization"
ditto -c -k --keepParent $appPath $appPreNotarizationZipPath

# distribute
# TODO
