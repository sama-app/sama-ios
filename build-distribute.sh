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
 -scheme sama \
 -configuration Release \
 -clonedSourcePackagesDirPath SourcePackages \
 -archivePath $archivePath \
 archive CODE_SIGN_STYLE=Manual \
 | xcpretty
set -o pipefail && \
 xcodebuild -exportArchive \
 -archivePath $archivePath \
 -exportOptionsPlist $EXPORT_OPTIONS_PLIST \
 -exportPath $buildPath \
 | xcpretty

# distribute
xcrun altool \
 --upload-app \
 --type ios \
--file "$buildPath/Sama.ipa" \
--apiKey "$APPSTORE_API_KEY" \
--apiIssuer "$APPSTORE_API_ISSUER"
