# critic.sh

![CI](https://github.com/Checksum/critic.sh/workflows/CI/badge.svg?branch=master)

---

Dead simple testing framework for Bash with coverage.

[![asciicast](https://asciinema.org/a/301445.svg)](https://asciinema.org/a/301445)

[![git-cloc](https://git-cloc.fly.dev/cloc/checksum/critic.sh/svg)](https://git-cloc.fly.dev/cloc/checksum/critic.sh)

## Why?

I was looking for a Bash testing framework with a familiar API and with coverage reporting. Although there are excellent frameworks like [bats-core](https://github.com/bats-core/bats-core), [shunit2](https://github.com/kward/shunit2) and [bashunit](https://github.com/djui/bashunit), I wasn't too comfortable with their API (not their fault). Also, I wanted some indication of coverage, so that it can be improved over time.

`critic.sh` exposes high level functions for testing consistent with other frameworks and a set of built in assertions. One of my most important goals was to be able to pass in any shell expression to the `_test` and `_assert` methods, so that one is not limited to the built-ins.

In addition, it can generate a lcov report. It tracks line and function coverage, but not branches. It works by running the tests with extended debugging, redirecting the trace output to a log file, and then parsing it to determine which functions/lines have been executed. It is currently a work in progress.

## Requirements

Due to use of certain bashisms, Bash v4.1+ is required. This may change in the future.

A tiny docker image is provided for convenience.

## Installation

There are a few ways to use `critic.sh`:

- Use the docker image

```bash
docker run --rm -v $(pwd):/work checksum/critic.sh '/work/src/*.sh' '/work/lib/*.sh'
```

You can pass a `CRITIC_SETUP` environment variable to run setup scripts before the tests are run. The docker image is based on alpine linux, so use `apk` to install packages:

```bash
docker run --rm -e CRITIC_SETUP='apk add --no-cache jq' -v $(pwd):/work checksum/critic.sh '/work/src/*.sh' '/work/lib/*.sh'
```

- Add this repository as a git submodule in your project

```bash
git submodule add https://github.com/Checksum/critic.sh critic
critic/critic.sh test.sh
```

- Copy `critic.sh` file into your project (not recommended)

## Usage

See `examples/test.sh` for detailed usage. To run the tests: `bash examples/test.sh`

#### Source the framework in your test file

```bash
# test-foobar.sh

# Include your source files
source foobar.sh
# Include the framework
source critic.sh

# Write tests
_describe foo
  _test "output should equal foo"
    _assert _output_equals "foo"

  _test "return code should be 0"
    _assert _return_true "Optional assertion message"
```

#### Pass the test file as an argument

```bash
critic.sh test-foobar.sh
```

## API

The layout of a test is consistent with other frameworks. You `_describe` a test suite, `_test` a function or expression, and `_assert` the output with a function or expression. The output, return code and arguments passed to the test are available as variables for all custom assertions.

### Test suite

| Function        | Description                                        | Arguments                                         |
| --------------- | -------------------------------------------------- | ------------------------------------------------- |
| \_describe      | Run test suite                                     | 1. Suite/Function name (\*)                       |
| \_describe_skip | Skip this test suite                               | 1. Suite/Function name (\*)                       |
| \_test          | Run a test                                         | 1. Test name (\*)                                 |
|                 |                                                    | 2. Test function/expression                       |
|                 |                                                    | 3. Arguments to forward to the test function      |
| \_test_skip     | Skip this test                                     | 1. Test name (\*)                                 |
|                 |                                                    | 2. Test function/expression                       |
|                 |                                                    | 3. Arguments to forward to the test function      |
| \_assert        | Run an assertion                                   | 1. Assertion function/expression (\*)             |
|                 |                                                    | 2. Arguments to forward to the assertion function |
| \_teardown      | Teardown function run after all tests have ben run |

### Assertions

| Function          | Description           | Arguments               |
| ----------------- | --------------------- | ----------------------- |
| \_return_true     | Return code == 0      | 1. Optional message     |
| \_return_false    | Return code != 0      | 1. Optional message     |
| \_return_equals   | Return code == num    | 1. Return code (\*)     |
|                   |                       | 2. Optional message     |
| \_output_contains | Output contains value | 1. Value (\*)           |
|                   |                       | 2. Optional message     |
| \_output_equals   | Output equals value   | 1. Value (\*)           |
|                   |                       | 2. Optional message     |
| \_not             | Negate an assertion   | 1. Assertion (\*)       |
|                   |                       | 2. Value (\*)           |
|                   |                       | 3. Optional message     |
| \_nth_arg_equals  | Nth arg equals value  | 1. Argument index (>=0) |
|                   |                       | 2. Value                |
|                   |                       | 3. Optional message     |

### Variables

After every `_test` is run, the following variables are set. These are useful for custom assertions:

| Variable | Description                                 |
| -------- | ------------------------------------------- |
| \_output | Output of the function/expression           |
| \_return | Return code                                 |
| \_args   | Arguments passed to the function/expression |

### Options

| Environment variable        | Description                                 | Default |
| --------------------------- | ------------------------------------------- | ------- |
| CRITIC_COVERAGE_DISABLE     | Disable coverage                            | false   |
| CRITIC_COVERAGE_MIN_PERCENT | Minimum coverage percent per source file    | 0       |
| CRITIC_COVERAGE_REPORT_CLI  | Print coverage report to CLI                | true    |
| CRITIC_COVERAGE_REPORT_LCOV | Save lcov report                            | true    |
| CRITIC_COVERAGE_REPORT_HTML | Generate HTML lcov report (requires `lcov`) | false   |
| CRITIC_DEBUG                | Prints more verbose messages                | false   |

### Annotations

##### Disable coverage for certain lines by wrapping them in `# critic ignore` and `# critic /ignore` blocks:

```bash
# critic ignore
foo() {
  echo "This function will skipped when calculating coverage %"
}
# critic /ignore
```
