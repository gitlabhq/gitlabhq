#!/usr/bin/env bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euo pipefail

HOST="$1"

printf 'Waiting for ES to be reachable ...'
until $(wget -O- -q "$HOST" &>/dev/null); do
    printf '.'
    sleep 1
done
echo " OK!"

printf 'Waiting for ES to be healthy ...'
while : ; do
    HEALTH="$(wget -O- -q "$HOST/_cat/health?h=status" 2> /dev/null)"
    HEALTH="$(echo "$HEALTH" | sed -r 's/^[[:space:]]+|[[:space:]]+$//g')" # trim whitespace (otherwise we'll have "green ")
    ([ "$HEALTH" != "green" ] && printf '.' && sleep 1) || break
done
echo " OK!"

echo "Elastic Search is up!"
