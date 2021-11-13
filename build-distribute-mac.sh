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

# notarize

appPath="$buildPath/Sama.app"
appPreNotarizationZipPath="$buildPath/Sama-pre-notarization.zip"
appZipPath="$buildPath/Sama.zip"
notarizationRequestPath="$buildPath/notarization-request.plist"
notarizationResultPath="$buildPath/notarization-result.plist"

ditto -c -k --keepParent $appPath $appPreNotarizationZipPath

xcrun altool \
 --notarize-app \
 --primary-bundle-id "com.meetsama.app.dev" \
 --apiKey "$APPSTORE_API_KEY" \
 --apiIssuer "$APPSTORE_API_ISSUER" \
 -f $appPreNotarizationZipPath \
 --output-format xml \
 > $notarizationRequestPath

while true; do
  xcrun altool \
    --notarization-info `/usr/libexec/PlistBuddy -c "Print :notarization-upload:RequestUUID" $notarizationRequestPath` \
    --apiKey "$APPSTORE_API_KEY" \
    --apiIssuer "$APPSTORE_API_ISSUER" \
    --output-format xml > $notarizationResultPath
  status=`/usr/libexec/PlistBuddy -c "Print :notarization-info:Status" $notarizationResultPath`
  if [ "$status" != "in progress" ]; then
    break;
  fi;
  sleep 10
done

xcrun stapler staple $appPath

ditto -c -k --keepParent $appPath $appZipPath

# distribute
# TODO
