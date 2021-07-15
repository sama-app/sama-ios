#!/bin/bash
type=$1

if [ "$type" = "prod" ] || [ "$type" == "dev" ]; then
  echo "Configuring environment for $type..."
  cp -rf "env/$type/GoogleService-Info.plist" "sama/GoogleService-Info.plist"
  cp -rf "env/$type/sama.xcconfig" "sama/Resources/sama.xcconfig"
  cp -rf "env/$type/SamaKeys.swift" "sama/Environment/SamaKeys.swift"
  cp -rf "env/$type/AppIcon.appiconset" "sama/Assets.xcassets/AppIcon.appiconset"
  exit 0
fi

echo "Couldn't find correct type (should be either prod or dev)"
exit 1