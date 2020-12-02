#!/bin/sh

git grep 'context.\(Background\|TODO\)' | \
    grep -v -e '^[^:]*_test\.go:' -v -e "lint:allow context.Background" -e '^vendor/' -e '^_support/' -e '^cmd/[^:]*/main.go' | \
    grep -e '^[^:]*\.go' | \
    awk '{
  print "Found disallowed use of context.Background or TODO"
  print
  exit 1
}'
