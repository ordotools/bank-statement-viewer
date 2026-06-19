#!/bin/bash
# Sign and notarize the .app for distribution outside your Mac.
# Requires: Developer ID Application cert, notarytool credentials.
set -euo pipefail

APP="${1:-build/Release/BankStatementViewer.app}"
IDENTITY="${SIGNING_IDENTITY:-Developer ID Application}"
TEAM_ID="${APPLE_TEAM_ID:-}"
KEYCHAIN_PROFILE="${NOTARY_PROFILE:-notarytool-profile}"

if [[ ! -d "${APP}" ]]; then
  echo "Usage: $0 path/to/BankStatementViewer.app"
  exit 1
fi

echo "Signing ${APP}..."
codesign --force --deep --options runtime --sign "${IDENTITY}" "${APP}/Contents/Resources/bin/bankparse" || true
codesign --force --deep --options runtime --sign "${IDENTITY}" "${APP}"

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "${APP}"

if [[ -z "${TEAM_ID}" ]]; then
  echo "Set APPLE_TEAM_ID to notarize. Signed app ready at ${APP}"
  exit 0
fi

ZIP="$(mktemp -t bankstatementviewer).zip"
ditto -c -k --keepParent "${APP}" "${ZIP}"

echo "Submitting for notarization..."
xcrun notarytool submit "${ZIP}" --keychain-profile "${KEYCHAIN_PROFILE}" --wait

xcrun stapler staple "${APP}"
echo "Notarized and stapled: ${APP}"
