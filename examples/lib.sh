#!/bin/bash

foo() {
    echo "foo"
}

# Prints bar
bar() {
    # Oops, I broke this!
    echo "baz"
}

# critic ignore
baz() {
    echo "baz"
}
# critic /ignore

foobar() {
    # Prints both foo and bar
    foo
    bar
}

echo_first() {
    echo "$1"
}

echo_second() {
    echo "$2"
}
