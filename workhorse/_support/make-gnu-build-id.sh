#!/bin/sh

main()
{
    GO_BINARY=$1

    if [ $# -ne 1 ] || [ ! -f $GO_BINARY ] ; then
        fail "Usage: $0 [path_to_go_binary]"
    fi

    GO_BUILD_ID=$( go tool buildid "$GO_BINARY" || openssl rand -hex 32 )
    if [ -z "$GO_BUILD_ID" ] ; then
        fail "ERROR: Could not extract Go build-id or generate a random hex string."
    fi

    GNU_BUILD_ID=$( echo $GO_BUILD_ID | sha1sum | cut -d' ' -f1 )
    if [ -z "$GNU_BUILD_ID" ] ; then
        fail "ERROR: Could not generate a GNU build-id"
    fi

    echo "$GNU_BUILD_ID"
}

fail()
{
    echo "$@" 1>&2
    exit 1
}

main "$@"
