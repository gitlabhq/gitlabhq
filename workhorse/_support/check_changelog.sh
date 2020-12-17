#!/bin/sh

set -e

# we skip the changelog check if the merge requet title ends with "NO CHANGELOG"
if echo "$CI_MERGE_REQUEST_TITLE" | grep -q ' NO CHANGELOG$'; then
    echo "Changelog not needed"

    exit 0
fi

target=${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-master}

if git diff --name-only "origin/$target" | grep -q '^changelogs/' ; then
    echo "Changelog included"
else
    echo "Please add a changelog running '_support/changelog'"
    echo "or disable this check adding 'NO CHANGELOG' at the end of the merge request title"
    echo "/title $CI_MERGE_REQUEST_TITLE NO CHANGELOG"

    exit 1
fi
