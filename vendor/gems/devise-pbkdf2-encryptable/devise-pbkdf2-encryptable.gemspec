# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'devise-pbkdf2-encryptable'
  spec.authors = ['Drew Blessing']
  spec.email = ['drew@gitlab.com']

  spec.summary = 'Extension that allows Devise to use PBKDF2 password hashing'
  spec.homepage = 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/devise-pbkdf2-encryptable'
  spec.metadata = { 'source_code_uri' => 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/devise-pbkdf2-encryptable' }
  spec.license = 'Apache-2.0'

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  spec.version = '0.0.0'

  spec.add_runtime_dependency 'devise', '~> 4.0'
  spec.add_runtime_dependency 'devise-two-factor', '~> 4.1.1'

  spec.add_development_dependency 'activemodel', '~> 7.0', '< 8'
  spec.add_development_dependency 'rspec', '~> 3.10.0'
end
