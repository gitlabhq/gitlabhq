#!/bin/bash

# Unfortunately, workhorse fails many lint checks which we currently ignore
#
LINT_KNOWN_ACCEPTABLE_FILE="_support/lint_last_known_acceptable.txt"
LINT_KNOWN_ACCEPTABLE="$(cat ${LINT_KNOWN_ACCEPTABLE_FILE})"

LINT_RESULT_FILE=$(mktemp /tmp/lint_result.XXXXXX)
LINT_RESULT=$(make --no-print-directory golangci | tee "${LINT_RESULT_FILE}")

if [[ "${LINT_RESULT}x" == "${LINT_KNOWN_ACCEPTABLE}x" ]]; then
  exit 0
else
  echo

  diff -u "${LINT_KNOWN_ACCEPTABLE_FILE}" "${LINT_RESULT_FILE}"

  echo
  echo "INFO: The above diff could be caused by a lint error being fixed _or_ newly added."
  echo "      If you believe the diff is as a result of a lint error being fixed, please run"
  echo "      the following and try re-running 'make lint' again:"
  echo
  echo "    make golangci > ${LINT_KNOWN_ACCEPTABLE_FILE}"
  echo
  echo "INFO: Take specific note of the go version used as the diffs can vary."
  echo

  exit 1
fi
