#/bin/bash

base=$1
convert "$base" -resize '40x40'     -unsharp 1x4 "app-icon~notification@2x.png"
convert "$base" -resize '60x60'     -unsharp 1x4 "app-icon~notification@3x.png"
convert "$base" -resize '58x58'     -unsharp 1x4 "app-icon~settings@2x.png"
convert "$base" -resize '87x87'     -unsharp 1x4 "app-icon~settings@3x.png"
convert "$base" -resize '80x80'     -unsharp 1x4 "app-icon~spotlight@2x.png"
convert "$base" -resize '120x120'   -unsharp 1x4 "app-icon~spotlight@3x.png"
convert "$base" -resize '120x120'   -unsharp 1x4 "app-icon@2x.png"
convert "$base" -resize '180x180'   -unsharp 1x4 "app-icon@3x.png"
convert "$base" -resize '1024x1024' -unsharp 1x4 "appstore-icon.png"
