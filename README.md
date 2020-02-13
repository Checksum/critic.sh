# critic.sh
Dead simple Bash unit testing with rudimentary coverage

## Requirements

bash v4.1+

## Usage

#### Source the framework in your test file

```bash
# test-foobar.sh

# Include the framework
source critic.sh

# Include your source files
source foobar.sh

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

| Function | Description | Arguments |
|----------|-------------|------------|
| _describe| Test suite declaration | 1. Suite/Function name (*) |
| _test    | Run a test | 1. Test name (*)
| | | 2. Test function/expression |
| | | 3. Arguments to forward to the test function |
| _assert  | Run an assertion | 1. Assertion function/expression (*) |
| | | 2. Arguments to forward to the assertion function |

### Assertions

| Function | Description | Arguments |
|----------|-------------|-----------|
| _return_true | Assert return code to be 0 | 1. Optional message
| _return_false| Assert return code to be non zero | 1. Optional message
| _return_equals | Assert return code | 1. Return code (*)
| | | 2. Optional message
| _contains | Assert output contains | 1. String (*)
| | | 2. Optional message
| _not_contains | Assert output does not contain | 1. String (*)
| | | 2. Optional message
| _equals | Assert output to equal | 1. String (*)
| | | 2. Optional message

### Variables
After every `_test` is run, the following variables are set. These are useful for custom assertions:

| Variable | Description |
|----------|-------------|
| _output  | Output of the function/expression
| _return  | Return code
| _args    | Arguments passed to the function/expression

