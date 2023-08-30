# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'mail-smtp_pool'
  spec.version = '0.1.0'
  spec.authors = ['Heinrich Lee Yu']
  spec.email = ['heinrich@gitlab.com']

  spec.summary = 'Mail extension for sending using an SMTP connection pool'
  spec.homepage = 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/mail-smtp_pool'
  spec.metadata = { 'source_code_uri' => 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/mail-smtp_pool' }
  spec.license = 'MIT'

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  # Please maintain alphabetical order for dependencies
  spec.add_runtime_dependency 'connection_pool', '~> 2.0'
  spec.add_runtime_dependency 'mail', '~> 2.8'

  # Please maintain alphabetical order for dev dependencies
  spec.add_development_dependency 'rspec', '~> 3.10.0'
end
