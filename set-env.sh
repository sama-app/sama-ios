#!/bin/bash
set -e
type=$1

ENV_PATH="sama/Environment"

GOOGLE_SERVICE_PATH="sama/GoogleService-Info.plist"
XCCONFIG_PATH="sama/Resources/sama.xcconfig"
KEYS_PATH="$ENV_PATH/SamaKeys.swift"
APP_ICON_PATH="sama/Assets.xcassets/AppIcon.appiconset"
ENTITLEMENTS_PATH="sama/sama.entitlements"

rm -f $GOOGLE_SERVICE_PATH
rm -f $XCCONFIG_PATH
rm -f $KEYS_PATH
rm -r -f $APP_ICON_PATH
rm -f $ENTITLEMENTS_PATH

SRC_PATH="env/$type"

if [ "$type" = "prod" ] || [ "$type" == "dev" ]; then
  echo "Configuring environment for $type..."
  cp -rf "$SRC_PATH/GoogleService-Info.plist" $GOOGLE_SERVICE_PATH
  cp -rf "$SRC_PATH/sama.xcconfig" $XCCONFIG_PATH
  mkdir -p $ENV_PATH
  cp -rf "$SRC_PATH/SamaKeys.swift" $KEYS_PATH
  cp -rf "$SRC_PATH/AppIcon.appiconset" $APP_ICON_PATH
  cp -rf "$SRC_PATH/sama.entitlements" $ENTITLEMENTS_PATH
  exit 0
fi

echo "Couldn't find correct type (should be either prod or dev)"
exit 1
