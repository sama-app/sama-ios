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
 -exportOptionsPlist "./env/dev/exportOptions-mac.plist" \
 -exportPath $buildPath \
 | xcpretty

# notarize

appPath="$buildPath/Sama.app"
appPreNotarizationZipPath="$buildPath/Sama-pre-notarization.zip"
appZipPath="$buildPath/Sama.zip"
notarizationRequestPath="$buildPath/notarization-request"
notarizationResultPath="$buildPath/notarization-result"

echo "zip pre notarization"
ditto -c -k --keepParent $appPath $appPreNotarizationZipPath

echo "notarize"
xcrun altool \
 --notarize-app \
 --primary-bundle-id "com.meetsama.app.dev" \
 --apiKey "$APPSTORE_API_KEY" \
 --apiIssuer "$APPSTORE_API_ISSUER" \
 -f $appPreNotarizationZipPath > $notarizationRequestPath

echo "wait for notarization result"
requestUUID=$(awk -F ' = ' '/RequestUUID/ {print $2}' "$notarizationRequestPath")
while true; do
  xcrun altool \
    --notarization-info "$requestUUID" \
    --apiKey "$APPSTORE_API_KEY" \
    --apiIssuer "$APPSTORE_API_ISSUER" > $notarizationResultPath
  if ! grep -q "Status: in progress" "$notarizationResultPath"; then
    break;
  fi
  sleep 10
done

echo "staple"
xcrun stapler staple $appPath

echo "zip notarized"
ditto -c -k --keepParent $appPath $appZipPath

# distribute
# TODO
