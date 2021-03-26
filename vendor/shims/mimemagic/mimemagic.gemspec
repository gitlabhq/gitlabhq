require_relative 'lib/mimemagic/version'

Gem::Specification.new do |spec|
  spec.name          = "mimemagic"
  spec.version       = MimeMagic::VERSION
  spec.authors       = ["Marc Shaw"]
  spec.email         = ["mshaw@gitlab.com"]

  spec.summary       = %q{MimeMagic shim}
  spec.description   = %q{A shim for mimemagic}
  spec.homepage      = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/shims/mimemagic"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.files = %w[lib/mimemagic.rb lib/mimemagic/version.rb]

  spec.require_paths = ["lib"]
end
