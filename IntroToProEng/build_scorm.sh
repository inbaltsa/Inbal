#!/usr/bin/env bash
# Builds lomda_scorm.zip (SCORM 1.2) from lomda/. Run from anywhere: ./build_scorm.sh
# Moodle serves index.html as-is, so the package copy gets a full document head
# (doctype, UTF-8 charset, viewport) that the artifact preview otherwise adds for us.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
src="$here/lomda"; out="$here/lomda_scorm.zip"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

{ printf '<!doctype html>\n<html lang="he" dir="rtl">\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
  sed 's|<script src="content.js"></script>|<script src="content.js" charset="utf-8"></script>|' "$src/index.html"
  printf '\n</html>\n'; } > "$tmp/index.html"
cp "$src/content.js" "$tmp/"
mkdir "$tmp/images"; cp "$src"/images/* "$tmp/images/"

files=$(cd "$tmp" && find images -type f | sort | sed 's|.*|      <file href="&"/>|')
cat > "$tmp/imsmanifest.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<manifest identifier="LOMDA_MEASURE_CURVES" version="1.2"
  xmlns="http://www.imsproject.org/xsd/imscp_rootv1p1p2"
  xmlns:adlcp="http://www.adlnet.org/xsd/adlcp_rootv1p2"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.imsproject.org/xsd/imscp_rootv1p1p2 imscp_rootv1p1p2.xsd http://www.adlnet.org/xsd/adlcp_rootv1p2 adlcp_rootv1p2.xsd">
  <metadata><schema>ADL SCORM</schema><schemaversion>1.2</schemaversion></metadata>
  <organizations default="ORG1"><organization identifier="ORG1">
    <title>מדידה והתאמת עקומות</title>
    <item identifier="ITEM1" identifierref="RES1" isvisible="true"><title>מדידה והתאמת עקומות</title><adlcp:masteryscore>70</adlcp:masteryscore></item>
  </organization></organizations>
  <resources><resource identifier="RES1" type="webcontent" adlcp:scormtype="sco" href="index.html">
      <file href="index.html"/>
      <file href="content.js"/>
$files
  </resource></resources>
</manifest>
XML

rm -f "$out"; (cd "$tmp" && zip -qr "$out" imsmanifest.xml index.html content.js images)
echo "built $out"
