#!/bin/bash

if [ -n "$1" ]; then
  ./SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols -gsp ./env/prod/GoogleService-Info.plist -p ios $1
else
  echo "dSYM path not defined"
  exit 1
fi
