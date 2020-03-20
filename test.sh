#!/usr/bin/env bash

# bash strict settings
set -o errexit # exit on errors
set -o nounset # exit on use of uninitialized variable
set -o pipefail

MY_PACKAGE='@liquid-labs/policy-home-lockdown'

cat <<EOF > settings.sh
# local parameters
SCOPE_STATEMENT='COVID-19 viral outbreak'
EOF

cleanup() {
  echo -n "Cleaning up... "
  rm node_modules/${MY_PACKAGE}
  rm settings.sh
  echo "done."
}

trap cleanup EXIT

BIN="$(npm bin)"
EXIT=0

echo "Preparing..."
rm -rf .build test-out
ln -s "$PWD" node_modules/${MY_PACKAGE}
POLICY_COUNT=$(cd node_modules/@liquid-labs && find -L . -path "./policy-*" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.yalc/*" -not -path "*/tmpl/*" | wc -l | awk '{print $1}')

echo -n "Test document parsing: "
"${BIN}/liq-init-docs" run test-out > /dev/null || { echo "FAIL"; EXIT=1; }
make -f .build/main.makefile --silent || { echo "FAIL"; EXIT=1; }
if (( $EXIT == 0 )); then echo "PASS"; fi

echo -n "Expect $POLICY_COUNT files; "
OUT_FILES=$(find test-out -type f | wc -l | awk '{print $1}')
echo -n "found $OUT_FILES: "
if (( $OUT_FILES == $POLICY_COUNT )); then
  echo "PASS"
else
  echo "FAIL"
  EXIT=1
fi

exit $EXIT
