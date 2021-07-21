#!/bin/sh

FLAG=-w
if [ "x$1" = xcheck ]; then
  FLAG=-e
fi

IMPORT_RESULT=$(
  goimports $FLAG -local "gitlab.com/gitlab-org/gitlab/workhorse" -l $(
    find . -type f -name '*.go' | grep -v -e /_ -e /testdata/ -e '^\./\.'
  )
)

case "x$1" in
  xcheck)
    if [ -n "${IMPORT_RESULT}" ]; then
      echo >&2 "Formatting or imports need fixing: 'make fmt'"
      echo "${IMPORT_RESULT}"
      exit 1
    fi
    ;;
  x)
    echo "${IMPORT_RESULT}"
    ;;
esac
