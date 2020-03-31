#!/usr/bin/env bash

source examples/lib.sh
source critic.sh

_describe_only foo
    # Since no function/expression is passed to _test,
    # it defaults to the test suite name (foo). So, the function
    # foo is invoked for each test
    _test "Should print foo"
        _assert _output_equals foo

_describe_only echo_first
    # If you want to pass arguments to the test function,
    # the function name has to be explicitly specified
    _test "Should get the correct number of args" echo_first "first arg" "second\\ arg"
        _assert _nth_arg_equals 0 "first arg" "First argument equals 0"
        _assert _nth_arg_equals 1 "second\\ arg"

_describe "custom expression"
    # The true expression means don't do anything
    # You can pass any bash expression there!
    _test "Should test custom expression" true
        _assert "[ 1 -eq 1 ]"
        _assert "[ 2 -eq 2 ]" "Two should be equal to two"