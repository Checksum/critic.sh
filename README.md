# critic.sh

Dead simple testing framework for Bash with rudimentary coverage.

## Requirements

Bash v4.1+

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
    _assert _equals "foo"

  _test "return code should be 0"
    _assert _return_true "Optional assertion message"
```

#### Pass the test file as an argument

```bash
critic.sh test-foobar.sh
```

## API

### Test suite

| Function   | Description          | Arguments                                         |
| ---------- | -------------------- | ------------------------------------------------- |
| \_describe | Declare a test suite | 1. Suite/Function name (\*)                       |
| \_test     | Run a test           | 1. Test name (\*)                                 |
|            |                      | 2. Test function/expression                       |
|            |                      | 3. Arguments to forward to the test function      |
| \_assert   | Run an assertion     | 1. Assertion function/expression (\*)             |
|            |                      | 2. Arguments to forward to the assertion function |

### Assertions

| Function         | Description           | Arguments               |
| ---------------- | --------------------- | ----------------------- |
| \_return_true    | Return code == 0      | 1. Optional message     |
| \_return_false   | Return code != 0      | 1. Optional message     |
| \_return_equals  | Return code == num    | 1. Return code (\*)     |
|                  |                       | 2. Optional message     |
| \_contains       | Output contains value | 1. Value (\*)           |
|                  |                       | 2. Optional message     |
| \_equals         | Output equals value   | 1. Value (\*)           |
|                  |                       | 2. Optional message     |
| \_not            | Negate an assertion   | 1. Assertion (\*)       |
|                  |                       | 2. Value (\*)           |
|                  |                       | 3. Optional message     |
| \_nth_arg_equals | Nth arg equals value  | 1. Argument index (>=0) |
|                  |                       | 2. Value                |
|                  |                       | 3. Optional message     |

### Variables

After every `_test` is run, the following variables are set. These are useful for custom assertions:

| Variable | Description                                 |
| -------- | ------------------------------------------- |
| \_output | Output of the function/expression           |
| \_return | Return code                                 |
| \_args   | Arguments passed to the function/expression |

### Options

| Environment variable        | Description                              |
| --------------------------- | ---------------------------------------- |
| CRITIC_COVERAGE_DISABLE     | Disable coverage                         |
| CRITIC_COVERAGE_MIN_PERCENT | Minimum coverage percent per source file |
| DEBUG                       | Prints more verbose messages             |

### Annotations

##### Disable coverage for certain lines by wrapping them in `# critic ignore` and `# critic /ignore` blocks:

```bash
# critic ignore
foo() {
  echo "This function will skipped when calculating coverage %"
}
# critic /ignore
```
