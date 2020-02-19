#!/usr/bin/env bash

_cleanOutput() {
    while read -r line; do
        # shellcheck disable=2001
        sed "s,$(printf '\033')\\[[0-9;]*[a-zA-Z],,g" <<< "$line" | awk '{$1=$1;print}' | awk /./
    done
}

_abspath() {
    # shellcheck disable=2164
    echo "$(cd "$(dirname "$1")"; pwd)"
}

_runTest() {
    local file="$1"
    local expectedCode="$2"
    local expectedOutput="$3"
    local output code

    echo "--- Running $file"

    output="$(bash "$file")"
    code=$?

    if [ $code -eq "$expectedCode" ]; then
        echo "Exit codes match"
    else
        echo "Exit codes do not match. Actual: $code, expected: $expectedCode"
        exitCode=$code
    fi

    if ! diff -bBEi \
        <(sed -n -e '/\[critic\] Coverage Report/,$p' <<< "$output" | _cleanOutput | tail -n +2 | head -n -1) \
        <(echo "$expectedOutput"); then
        exitCode=1
    else
        echo "Outputs match"
    fi
}

exitCode=0

expected="$(cat <<EOF
$(pwd)/examples/lib.sh
Total LOC: 19
Covered LOC: 3
Coverage %: 50
Ignored LOC: 5
Uncovered Lines: 21 22 30
EOF
)"

_runTest "examples/test.sh" 1 "$expected"

exit $exitCode
