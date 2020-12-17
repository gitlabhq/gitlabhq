#!/bin/sh

git grep 'testify/assert"' | \
    grep -e '^[^:]*\.go' | \
    awk '{
  print "error: please use testify/require instead of testify/assert"
  print
  exit 1
}'
