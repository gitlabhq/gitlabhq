#!/bin/sh

# Unfortunately, workhorse fails many lint checks which we currently ignore
LINT_RESULT=$(golint "$@"|grep -Ev 'should have|should be|use ALL_CAPS in Go names')

if [ -n "${LINT_RESULT}" ]; then
  echo >&2 "Formatting or imports need fixing: 'make fmt'"
  echo ">>${LINT_RESULT}<<"
  exit 1
fi

