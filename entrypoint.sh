#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

if [ $# -eq 0 ]; then
  echo "Usage: docker run --rm -v $(pwd):/work checksum/critic.sh '/work/src/*.sh' '/work/lib/*.sh'"
  exit 99
fi

skipFile() {
  for file in entrypoint.sh critic.sh; do
    if cmp -s "/home/$file" "$1"; then
      return 0
    fi
  done
  return 1
}

testFiles=()
for file in $@; do
  if ! skipFile "$file"; then
    testFiles+=("$file")
  fi
done

if [ "${#testFiles[@]}" -eq 0 ]; then
  echo "No tests to run"
else
  if [ -n "$CRITIC_SETUP" ]; then
    eval "$CRITIC_SETUP"
  fi
  for file in "${testFiles[@]}"; do
    ./critic.sh "$file"
  done
fi
