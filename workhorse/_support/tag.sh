set -e

main() {
  version=$1
  set_version

  changelog

  git commit VERSION -m "Update VERSION to $version"

  tag_name="v${version}"
  git tag $TAG_OPTS -m "Version ${version}" -a ${tag_name}
  git show ${tag_name}
  cat <<'EOF'

  Remember to now push your tag, either to gitlab.com (for a
  normal release) or dev.gitlab.org (for a security release).
EOF
}

set_version() {
  if ! echo "${version}" | grep -q '^[0-9]\+\.[0-9]\+\.[0-9]\+$' ; then
    echo "Invalid VERSION: ${version}"
    exit 1
  fi

  if git tag --list | grep -q "^v${version}$" ; then
    echo "Tag already exists for ${version}"
    exit 1
  fi

  echo "$version" > VERSION
}

changelog() {
  _support/generate_changelog "$version"

  git commit CHANGELOG changelogs/unreleased --file - <<EOF
Update CHANGELOG for ${version}

[ci skip]
EOF
}

main "$@"
