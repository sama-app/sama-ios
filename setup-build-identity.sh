#/bin/bash
set -e

# create variables
BUILD_CERT_PATH=$RUNNER_TEMP/build_certificate.p12
DEV_ID_CERT_PATH=$RUNNER_TEMP/developer_id_certificate.p12
MAC_INSTALLER_CERT_PATH=$RUNNER_TEMP/mac_installer_certificate.p12
PP_PATH=$RUNNER_TEMP/build_pp.mobileprovision
KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

# import certificate and provisioning profile from secrets
echo -n "$BUILD_CERT_BASE64" | base64 --decode --output $BUILD_CERT_PATH
echo -n "$DEV_ID_CERT_BASE64" | base64 --decode --output $DEV_ID_CERT_PATH
echo -n "$MAC_INSTALLER_CERT_BASE64" | base64 --decode --output $MAC_INSTALLER_CERT_PATH
echo -n "$BUILD_PROVISIONING" | base64 --decode --output $PP_PATH

# create temporary keychain
security create-keychain -p "$KEYCHAIN_PASS" $KEYCHAIN_PATH
security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
security unlock-keychain -p "$KEYCHAIN_PASS" $KEYCHAIN_PATH

# import certificate to keychain
security import $BUILD_CERT_PATH -P "$BUILD_CERT_PASS" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
security import $DEV_ID_CERT_PATH -P "$DEV_ID_CERT_PASS" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
security import $MAC_INSTALLER_CERT_PATH -P "$MAC_INSTALLER_CERT_PASS" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
security list-keychain -d user -s $KEYCHAIN_PATH

# apply provisioning profile
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp $PP_PATH ~/Library/MobileDevice/Provisioning\ Profiles
