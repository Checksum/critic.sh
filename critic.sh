#!/usr/bin/env bash
set -euo pipefail

# critic.sh - Dead simple testing framework for Bash with coverage.
# https://github.com/Checksum/critic.sh

# MIT License
# Copyright (c) 2020 Srinath Sankar

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

if [[ "${BASH_VERSION:0:1}" -lt 4 || \
    ("${BASH_VERSION:0:1}" -eq 4 && "${BASH_VERSION:2:1}" -lt 1) \
]]; then
    echo "critic.sh needs bash version >= 4.1"
    exit 99
fi

# Options
CRITIC_TRACE_FILE="$(pwd)/.critic-trace-$(date +%s).log"
CRITIC_COVERAGE_DISABLE="${CRITIC_COVERAGE_DISABLE:-}"
CRITIC_COVERAGE_MIN_PERCENT="${CRITIC_COVERAGE_MIN_PERCENT:-0}"
CRITIC_COVERAGE_REPORT_CLI="${CRITIC_COVERAGE_REPORT_CLI:-true}"
CRITIC_COVERAGE_REPORT_LCOV="${CRITIC_COVERAGE_REPORT_LCOV:-true}"
CRITIC_COVERAGE_REPORT_HTML="${CRITIC_COVERAGE_REPORT_HTML:-false}"


# Colors
DEFAULT='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'

# Variables exported to the tests
export _test_suite=''
export _args=()
export _output=''
export _return=0

# State
THIS_FILE="$(basename "${BASH_SOURCE[0]}")"
TEST_FILE="$(basename "${1:-"$0"}")"
PASS_COUNT=0
FAIL_COUNT=0


# Public API
_run() {
  local file="${1:-$(basename "$0")}"
  echo -e "${MAGENTA}[critic] Running tests in ${file}${DEFAULT}"
  # shellcheck disable=1090
  source "$file"
}

_describe() {
  _test_suite="${1:?'Test suite name expected as parameter 1'}"
  _skip_tests=false
  echo -e "\n${YELLOW}${1}${DEFAULT}"
}

_describe_skip() {
  _test_suite="${1:?'Test suite name expected as parameter 1'}"
  _skip_tests=suite
  echo -e "\n${YELLOW}${1} (skip)${DEFAULT}"
}

_test() {
  local test_id="$(slugify "$_test_suite" "$@")"
  local name="${1:?'Test name expected as parameter 1'}"; shift
  local fn_or_expr="${1:-}"; [ $# -gt 0 ] && shift

  # Determine if tests have to be run
  if [[ "$_skip_tests" == suite || ("$_skip_tests" == true && "${_test_id:-}" == "$test_id") ]]; then
    echo -e "  ${BLUE}${name} (skip)${DEFAULT}"
    return
  else
    _test_id="$test_id"
    _skip_tests=false
    echo -e "  ${BLUE}${name}${DEFAULT}"
  fi

  # If fn is not passed and _test_suite is a valid function, default to that
  if [ -z "$fn_or_expr" ]; then
    if declare -f "$_test_suite" &> /dev/null; then
      fn_or_expr="$_test_suite"
    else
      echo 'Test Function or expression expected as parameter 2' >&2
      exit 2
    fi
  fi

  # If expression, unset all positional parameters
  if ! declare -f "$fn_or_expr" &> /dev/null; then
    set --
  fi
  # Quote arguments to pass to eval, but save the unmodified
  # args to check assertions
  _args=("$@")
  if [ $# -gt 0 ]; then
    local tokens=()
    for token in "${_args[@]}"; do tokens+=( "$(printf '%q' "$token")" ); done
    set -- "${tokens[@]}"
  fi

  set +e
  _output="$(eval "$fn_or_expr" "$@" 2>&1)"
  _return=$?
  set -e
}

_test_skip() {
  _test_id="$(slugify "$_test_suite" "$@")"
  _skip_tests=true
  _test "$@"
}

_assert() {
  [ "${_skip_tests}" != false ] && return

  local fn_or_expr="${1:?'Assertion function or expression expected as parameter 1'}"; shift
  # shellcheck disable=2155
  local msg="$(_generate_assertion_msg "$fn_or_expr" "$@")"
  : "${msg:?'Assertion message expected as last parameter'}"

  # If expression, unset all positional parameters
  if ! declare -f "$fn_or_expr" &> /dev/null; then
    set --
  fi
  # Quote arguments to pass to eval
  if [ $# -gt 0 ]; then
    local tokens=()
    for token in "$@"; do tokens+=( "$(printf '%q' "$token")" ); done
    set -- "${tokens[@]}"
  fi

  if eval "$fn_or_expr" "$@"; then
    _pass "$msg"
  else
    _fail "$msg"
  fi
}


# Assertions
_return_true() {
  [ "${1:-$_return}" -eq 0 ]
}

_return_false() {
  [ "${1:-$_return}" -ne 0 ]
}

_return_equals() {
  [ "$_return" -eq "$1" ]
}

_output_contains() {
  grep -Fqi "$1" <<< "$_output"
}

_not() {
  local assertion="${1:?"Assertion to negate expected as parameter 1"}"; shift
  ! "$assertion" "$@"
}

_output_equals() {
  [ "$_output" = "$1" ]
}

_nth_arg_equals() {
  local n="${1:-"Position of arg expected as parameter 1 (zero indexed)"}"
  local expected="${2:-"Expected value should be parameter 2"}"
  [ "${_args[$n]}" = "${expected}" ]
}

# Private
_pass() {
  ((PASS_COUNT+=1))
  echo -e "    ${GREEN}PASS ✔ ${DEFAULT}: $1"
  [ -z "${CRITIC_DEBUG:-}" ] || _log_output "$@"
}

_fail() {
  ((FAIL_COUNT+=1))
  echo -e "    ${RED}FAIL ✘ ${DEFAULT}: $1"
  _log_output "$@"
}

_log_output() {
  cat <<OUTPUT
    --------
    Exit Code: ${2:-$_return}
    Output: ${3:-$_output}
    Arguments(${#_args[@]}): $(for a in ${_args[@]+"${_args[@]}"}; do echo -n "$a, "; done)
    --------
OUTPUT
}

_generate_assertion_msg() {
  case "$1" in
    _return_true) echo "${2:-"Exit code is 0"}";;
    _return_false) echo "${2:-"Exit code is non-zero"}";;
    _return_equals) echo "${3:-"Exit code is $2"}";;
    _output_equals) echo "${3:-"Output equals '$2'"}";;
    _output_contains) echo "${3:-"Output contains '$2'"}";;
    _nth_arg_equals) echo "${4:-"Nth argument $2 equals '$3'"}";;
    _not) echo "${4:-"Not${2//_/ } '$3'"}";;
    *) echo "${2:-"$1"}";;
  esac
}

_abspath() {
  echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

_uniq_array() {
  printf '%s\n' "$@" | tr ' ' '\n' | sort | uniq -u | sort -V | tr '\n' ' '
}

join_by() {
  local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}";
}

# https://gist.github.com/oneohthree/f528c7ae1e701ad990e6#gistcomment-2602836
slugify() {
  echo "$*" | sed -E 's/[~\^]+//g' | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+\|-+$//g' | tr A-Z a-z
}

_collect_coverage() {
  # disable extra debug info
  set +xo functrace

  local trace_lines parts filename lineno args
  declare -A -g coverage_map source_functions covered_functions covered_lines_count
  declare -a -g covered_lines all_functions source_files

  # Get extra debug info so that we can determine which file
  # a function belongs to (declare -F foobar)
  shopt -s extdebug
  # Collect functions to calculate coverage
  # all_functions includes functions in critic.sh and the test-foo.sh file,
  # so we filter them out
  # source_functions is a map with [function_name]="source_file:line_no"
  while IFS='' read -r line; do all_functions+=( "${line/declare -f* }" ); done < <(declare -F)
  for fn_name in "${all_functions[@]}"; do
    fn_declaration="$(declare -F "$fn_name" | tr -s  ' ')"
    source_file="$(echo "$fn_declaration" | cut -d ' ' -f3)"
    fn_source="$(basename "${source_file}" )"
    if ! [[ "$fn_source" == "${THIS_FILE}" || "$fn_source" == "${TEST_FILE}" ]]; then
      source_file="$(_abspath "$source_file")"
      fn_line="$(echo "$fn_declaration" | cut -d ' ' -f2)"
      source_functions["$fn_name"]="$source_file:$fn_line"
      source_files+=( "$source_file" )
    fi
  done
  shopt -u extdebug

  # Read all trace entries excluding this file (critic.sh)
  # and the test file which sources this file (test-foo.sh)
  while IFS='' read -r line; do trace_lines+=( "$line" ); done < \
    <(awk "!/^\++\(.*${TEST_FILE}|${THIS_FILE}/" "${CRITIC_TRACE_FILE}")

  for line in "${trace_lines[@]}"; do
    if [ "${line:0:1}" != '+' ]; then
      continue
    fi
    parts=($(echo "${line//':|:'/$'\n'}"))
    entry="${parts[0]##+*(}"
    entry="${entry%\)}"
    IFS=: read -r filename lineno <<< "$entry"
    filename="$(_abspath "$filename")"
    expression="${parts[1]% }"
    expression="${expression%()}"
    args="${parts[2]:-}"

    # If function, add to covered_functions map with [function name]="args"
    if [ -n "${source_functions[$expression]+unset}" ]; then
      covered_functions[$expression]="$(( ${covered_functions[$expression]:-0} + 1 ))"
    fi
    # Number of times a line is covered (for lcov)
    covered_lines_count["$lineno"]="$(( ${covered_lines_count[$lineno]:-0} + 1 ))"
    # Add to lines covered, this can be functions or expressions
    # Don't worry about duplicates yet
    coverage_map["$filename"]+="$lineno "
  done

  # Deduplicate source files
  source_files=($(printf "%s\n" "${source_files[@]}" | sort -uV))

  # Print coverage
  echo -e "\n${MAGENTA}[critic] Coverage Report${DEFAULT}"
  for file in "${source_files[@]}"; do
    # Lines in the file as an array
    total_lines=($(eval echo "{1..$(wc -l < "$file" | tr -d  ' ')}"))
    # Total #loc excluding empty lines, comments
    num_total_loc="$(sed '/^ *#/d;/^ *$/d' "${file}" | wc -l | tr -d ' ')"
    # Lines in the file which are empty or comments
    empty_lines=($(awk '/^ *#/ || /^ *$/ || /^ *(function)?.+\(\).*{$/ || /^ *} *$/ {print NR}' "${file}"))
    # Total #loc excluding empty lines, comments and function declaration statements
    coverage_lines=($(_uniq_array "${total_lines[@]}" "${empty_lines[@]}"))
    # Ignored lines as an array
    ignored_lines=($(awk '/# *critic ignore/,/# *critic \/ignore/ {print NR}' "${file}"))
    # Covered lines as an array
    IFS=' ' read -r -a covered_lines <<< "${coverage_map[$file]:-}"
    covered_lines=($(_uniq_array "${covered_lines[@]}"))
    # These lines have to be ignored from coverage % calculation
    lines_to_ignore_from_coverage=("${ignored_lines[@]}" "${empty_lines[@]}")
    lines_to_ignore_from_coverage=($(printf "%s\n" "${lines_to_ignore_from_coverage[@]}" | sort -uV))

    # For every source file, automatically add lines to coverage for heredoc
    # expressions if the first line with the heredoc declaration is covered
    # heredocs = (lineno<<start, lineno<<start)
    heredocs=($(awk '{ for(i=1;i<=NF;i++) if($i ~ /^<</ && $i != "<<<") print NR $i }' "$file"))
    for heredoc in ${heredocs[@]+"${heredocs[@]}"}; do
      IFS=$' ' read -r startline marker <<< "${heredoc/\<\</ }"
      # If the startline is already covered, add the entire heredoc definition
      for c in "${covered_lines[@]}"; do
        if [ "$c" -eq "$startline" ]; then
          while read -r lineno; do
            covered_lines+=( "$lineno" );
          done < <(awk "NR==$((startline+1)),/^${marker}$/{print NR}" "$file")
          break
        fi
      done
    done

    # Calculation and de-duplication
    # NOTE TO SELF: DON'T TOUCH THIS UNLESS YOU UNDERSTAND WHAT YOU'RE DOING!!!
    lines_to_cover=($(_uniq_array "${ignored_lines[@]}" "${coverage_lines[@]}" "${ignored_lines[@]}"))
    uncovered_lines=($(_uniq_array "${total_lines[@]}" "${lines_to_ignore_from_coverage[@]}"))
    uncovered_lines=($(printf "%s\n" "${uncovered_lines[@]}" | sort -uV))
    uncovered_lines=($(_uniq_array "${uncovered_lines[@]}" "${covered_lines[@]}"))
    if [ ${#lines_to_cover[@]} -gt 0 ]; then
      num_coverage_percent="$((${#covered_lines[@]} * 100 / ${#lines_to_cover[@]}))"
      num_coverage_percent="$(($num_coverage_percent > 100 ? 100 : $num_coverage_percent))"
    else
      num_coverage_percent=100
    fi

    CRITIC_REPORT_CLI+="$(_cli_report)"
    CRITIC_REPORT_LCOV+="$(_lcov_report)"
  done
}

# http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php
_lcov_report() {
  cat <<REPORT
TN:
SF:$file
$(for k in "${!source_functions[@]}"; do
    local path lineno
    IFS=: read -r path lineno <<< "${source_functions[$k]}"
    if [ "$path" = "$file" ]; then
        echo "FN:$lineno,$k"
    fi
done)
$(for k in "${!source_functions[@]}"; do
    if [ -n "${covered_functions[$k]+unset}" ]; then
        echo "FNDA:${covered_functions[$k]},$k"
    fi
done)
$(for l in "${!covered_lines_count[@]}"; do
    echo "DA:$l,${covered_lines_count[$l]}"
done)
$(for l in "${empty_lines[@]}"; do
    echo "DA:$l,1"
done)
$(for l in "${ignored_lines[@]}"; do
    echo "DA:$l,1"
done)
LF:$((${#lines_to_cover[@]} + ${#empty_lines[@]} + ${#ignored_lines[@]}))
LH:${#covered_lines[@]}
end_of_record
REPORT
}

_cli_report() {
  # Print report
  echo -e "\n${CYAN}$file${DEFAULT}"
  echo -e "  ${MAGENTA}Total LOC: ${num_total_loc}${DEFAULT} "
  echo -e "  ${GREEN}Covered LOC: ${#covered_lines[@]}${DEFAULT} "
  if [ "${num_coverage_percent}" -lt "${CRITIC_COVERAGE_MIN_PERCENT}" ]; then
    echo -en "${RED}"
  else
    echo -en "${GREEN}"
  fi
  echo -e "  Coverage %: ${num_coverage_percent}${DEFAULT}"
  echo -e "  ${YELLOW}Ignored LOC: ${#ignored_lines[@]}${DEFAULT} "
  echo -e "  ${RED}Uncovered Lines: ${uncovered_lines[*]:-none}"
  echo -e "${DEFAULT}"

  # Debug info
  if [ -n "${CRITIC_DEBUG:-}" ]; then
    echo -e "\n  Debug info\n"
    echo "    Trace file: ${CRITIC_TRACE_FILE}"
    echo "    # lines in file: ${#total_lines[@]}"
    echo "    # lines of code: ${num_total_loc}"
    echo "    Empty lines: ${empty_lines[*]}"
    echo "    Ignored lines: ${ignored_lines[*]}"
    echo "    Covered lines: ${covered_lines[*]}"
  fi
}

_coverage_report() {
  _collect_coverage

  if [ "$CRITIC_COVERAGE_REPORT_CLI" = true ]; then
    echo -e "$CRITIC_REPORT_CLI"
  fi
  if [[ "$CRITIC_COVERAGE_REPORT_LCOV" = true ]]; then
    rm -rf coverage && mkdir -p coverage
    echo "$CRITIC_REPORT_LCOV" > "coverage/lcov.info"
    if [[ "$CRITIC_COVERAGE_REPORT_HTML" = true ]]; then
      if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/report &> /dev/null
      else
        echo -e "${YELLOW}genhtml not found in path, have you install lcov - "
          "http://ltp.sourceforge.net/coverage/lcov.php${DEFAULT}"
      fi
    fi
  fi
}

_print_usage() {
  cat <<EOF
critic.sh - Dead simple testing framework for bash

Usage:
  critic.sh /path/to/test.sh

https://github.com/Checksum/critic.sh
EOF
}

_finish_tests() {
  local exit_code=$?
  if [ "${_print_report:-}" = false ]; then
    return 0
  fi

  # Generate and print coverage report
  [ -z "${CRITIC_COVERAGE_DISABLE}" ] && { _coverage_report || true; }
  # Print summary
  echo -e "\n${MAGENTA}[critic] Tests completed.${DEFAULT}" \
    "${GREEN}Passed: ${PASS_COUNT}${DEFAULT}, ${RED}Failed: ${FAIL_COUNT}${DEFAULT}"
  # Remove trace file
  [ -z "${CRITIC_DEBUG:-}" ] && rm -rf "${CRITIC_TRACE_FILE}"
  # Teardown
  declare -f _teardown &> /dev/null && { _teardown || true; }
  # Exit with number of failed tests
  [ $exit_code -eq 0 ] && exit ${FAIL_COUNT} || exit $exit_code
}
trap _finish_tests EXIT

# Setup if coverage is enabled
if [ -z "${CRITIC_COVERAGE_DISABLE}" ]; then
  # Redirect all trace info to a temp file rather
  # than printing to stdout. This requires bash 4.1
  exec 13> "${CRITIC_TRACE_FILE}"
  export BASH_XTRACEFD="13"
  # Ensure the trace is written in this format
  export PS4="+(\${BASH_SOURCE}:\${LINENO}):|:\${FUNCNAME[0]:+\${FUNCNAME[0]}():|:}"
  # Turn on some extended tracing
  set -xo functrace
fi

# Run if invoking via this script
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  if [ $# -eq 0 ]; then
    _print_usage
    _print_report=false
    exit 0
  fi
  _run "$1"
fi
