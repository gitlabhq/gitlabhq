# frozen_string_literal: true

require_relative 'lib/bundler_checksum/version'

Gem::Specification.new do |spec|
  spec.name          = 'bundler-checksum'
  spec.version       = BundlerChecksum::VERSION
  spec.authors       = ['dustinmm80']
  spec.email         = ['dcollins@gitlab.com']

  spec.summary       = 'Track checksums locally with Bundler'
  spec.description   = 'Track checksums locally with Bundler'
  spec.homepage      = 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/bundler-checksum'
  spec.license       = 'MIT'

  spec.files         = Dir['bin/*', 'lib/**/*.rb']
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bundler'
end
