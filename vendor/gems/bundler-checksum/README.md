# bundler-checksum

Bundler patch for verifying local gem checksums

## Install

Add the following to your Gemfile:

```
if ENV.fetch('BUNDLER_CHECKSUM_VERIFICATION_OPT_IN', 'false') != 'false' # this verification is still experimental
  require 'bundler-checksum'
  BundlerChecksum.patch!
end
```

## Usage

Once the gem is installed, bundler-checksum will verify gems before
installation.

If a new or updated gem is to be installed, the remote checksum of that gem is stored in `Gemfile.checksum`.
Checksum entries for other versions of the gem are removed from `Gemfile.checksum`.

If a version of a gem is to be installed that is already present in `Gemfile.checksum`, the remote and local
checksums are compared and an error is prompted if they do not match.

Gem checksums for all platforms are stored in `Gemfile.checksum`.
When `bundler-checksum` runs it will only verify the checksum for the platform that `bundle` wants to download.


## Development

