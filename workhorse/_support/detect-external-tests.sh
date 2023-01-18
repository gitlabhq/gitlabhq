#!/bin/sh
go list -f '{{join .XTestGoFiles "\n"}}' ./... | awk '
  { print }
  END {
    if(NR>0) {
      print "Please avoid using external test packages (package foobar_test) in Workhorse."
      print "See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107373."
      exit(1)
    }
  }
'
