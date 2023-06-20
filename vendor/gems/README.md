# Vendored Gems

This folder is used to store externally pulled dependencies.

## Development guidelines

The data stored in this directory should adhere to the following rules:

- MUST: Contain `GITLAB.md` to indicate where this data was pulled
  from with a description of what changes were made.
- MUST: Be added to `.gitlab/ci/vendored-gems.gitlab-ci.yml`.
- MUST NOT: Reference source code from outside of `vendor/gems/` or `require_relative "../../lib"`.
- MUST NOT: Require other gems that would result in circular dependencies.
- SHOULD NOT: Be published to RubyGems under our name.
- SHOULD: Be used with `gem <name>, path: "vendor/mail-smtp_pool"`.
- RECOMMENDED: Be added to `CODEOWNERS`.
- MAY: Reference other Gems in `vendor/gems/` with `gem <name>, path: "../mail-smtp_pool"`.
- MAY: Contain our patches to make them work with the GitLab monorepo, for example to continue to support deprecated or unmaintained dependences.
