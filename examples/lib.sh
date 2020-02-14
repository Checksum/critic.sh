#!/bin/bash

foo() {
    echo "foo"
}

# Prints bar
bar() {
    echo "bar"
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

echo-first() {
    echo "$1"
}

echo-second() {
    echo "$2"
}
