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

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
end
