#!/usr/bin/env bash

source examples/lib.sh
source critic.sh

# Test suite
_describe foo
    # Since no function/expression is passed to _test,
    # it defaults to the test suite name (foo). So, the function
    # foo is invoked for each test
    _test "Should print foo"
        _assert _output_equals foo

_describe bar
    _test "Should not print baz"
        _assert _not _output_equals baz

_describe echo_first
    # If you want to pass arguments to the test function,
    # the function name has to be explicitly specified
    _test "Should get the correct number of args" echo_first "first arg" "second\\ arg"
        _assert _nth_arg_equals 0 "first arg" "First argument equals 0"
        _assert _nth_arg_equals 1 "second\\ arg"

    # The true expression means don't do anything
    # You can pass any bash expression there!
    _test "Should test custom expression" true
        _assert "[ 1 -eq 1 ]"
        _assert "[ 2 -eq 2 ]" "Two should be equal to two"


# This is just a regular script, so setup tests as you like!
readme="$(cat <<EOF
critic.sh test file

Usage: test.sh foo|bar
EOF
)"

_describe "readme"
    _test "Should print readme" "echo \$readme"
        _assert _output_contains "foo|bar" "Readme contains options"
        _assert _output_contains "critic.sh"
