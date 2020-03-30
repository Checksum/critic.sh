#!/usr/bin/env bash

_trimColors() {
    while read -r line; do
        # shellcheck disable=2001
        sed "s,$(printf '\033')\\[[0-9;]*[a-zA-Z],,g" <<< "$line"
    done
}

_trimOutput() {
    while read -r line; do
        echo "$line" | awk '{$1=$1;print}' | awk /./
    done
}

_abspath() {
    # shellcheck disable=2164
    echo "$(cd "$(dirname "$1")"; pwd)"
}

_runTest() {
    local file="$1"
    local expectedCode="${2:-}"

    output="$(bash "$file")"
    code=$?

    if [ $code -eq "$expectedCode" ]; then
        echo "Exit codes match"
    else
        echo "Exit codes do not match. Actual: $code, expected: $expectedCode"
        exitCode=$code
    fi
}

exitCode=0
export CRITIC_COVERAGE_REPORT_HTML=false

echo "--- Coverage report"
_runTest "examples/test.sh" 1

expectedCoverage="$(cat <<EOF
$(pwd)/examples/lib.sh
Total LOC: 19
Covered LOC: 3
Coverage %: 50
Ignored LOC: 5
Uncovered Lines: 21 22 30
[critic] Tests completed. Passed: 7, Failed: 1
EOF
)"

if ! diff -bBEi \
    <(sed -n -e '/\[critic\] Coverage Report/,$p' <<< "$output" | _trimColors | _trimOutput | tail -n +2) \
    <(echo "$expectedCoverage"); then
    exitCode=1
else
    echo "Coverage report matches"
fi

echo "--- _output_contains"
expectedOutput="$(cat <<EOF
readme
Should print readme
PASS ✔ : Readme contains options
PASS ✔ : Output contains 'critic.sh'
EOF
)"
if ! diff -bBEi \
    <(echo "$output" | _trimColors | awk '/^readme/,/^ *$/' | _trimOutput) \
    <(echo "$expectedOutput"); then
    exitCode=1
else
    echo "Output matches"
fi

exit $exitCode
