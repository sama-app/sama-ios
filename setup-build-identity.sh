#/bin/bash
set -e

# create variables
BUILD_CERT_PATH=$RUNNER_TEMP/build_certificate.p12
DEV_ID_CERT_PATH=$RUNNER_TEMP/developer_id_certificate.p12
MAC_INSTALLER_CERT_PATH=$RUNNER_TEMP/mac_installer_certificate.p12
BUILD_PP_PATH=$RUNNER_TEMP/build_pp.mobileprovision
DEV_ID_PP_PATH=$RUNNER_TEMP/dev_id_pp.mobileprovision
BUILD_MAC_PP_PATH=$RUNNER_TEMP/build_mac_pp.mobileprovision
KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

# import certificate and provisioning profile from secrets
echo -n "$BUILD_CERT_BASE64" | base64 --decode --output $BUILD_CERT_PATH
echo -n "$DEV_ID_CERT_BASE64" | base64 --decode --output $DEV_ID_CERT_PATH
echo -n "$MAC_INSTALLER_CERT_BASE64" | base64 --decode --output $MAC_INSTALLER_CERT_PATH
echo -n "$BUILD_PROVISIONING" | base64 --decode --output $BUILD_PP_PATH
echo -n "$BUILD_MAC_PROVISIONING" | base64 --decode --output $BUILD_MAC_PP_PATH
echo -n "$DEV_ID_PROVISIONING" | base64 --decode --output $DEV_ID_PP_PATH

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
cp $BUILD_PP_PATH ~/Library/MobileDevice/Provisioning\ Profiles
build_mac_pp_uuid=`grep UUID -A1 -a $BUILD_MAC_PP_PATH | grep -io "[-A-F0-9]\{36\}"`
mv $BUILD_MAC_PP_PATH "~/Library/MobileDevice/Provisioning Profiles/$build_mac_pp_uuid.mobileprovision"
# cp $DEV_ID_PP_PATH ~/Library/MobileDevice/Provisioning\ Profiles
