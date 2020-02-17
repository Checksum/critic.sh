#!/usr/bin/env bash

output="$(bash examples/test.sh)"
code=$?

function cleanupOutput() {
    while read -r line; do
        sed "s,$(printf '\033')\\[[0-9;]*[a-zA-Z],,g" <<< "$line" | awk '{$1=$1;print}'
    done
}

expected="$(cat <<EOF
/Users/srinath/Projects/github.com/Checksum/critic.sh/examples/lib.sh
Total LOC: 19
Covered LOC: 3
Coverage %: 50
Ignored LOC: 5
Uncovered Lines: 21 22 30
EOF
)"

[ $code -eq 1 ] && echo "Exit codes match" || { echo "$output"; exit $code; }

diff -bBEi \
    <(sed -n -e '/\[critic\] Coverage Report/,$p' <<< "$output" | cleanupOutput | tail -n +2 | head -n -1) \
    <(echo "$expected") \
    && echo "Outputs match"
