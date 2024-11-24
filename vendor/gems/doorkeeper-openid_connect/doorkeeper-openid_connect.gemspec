# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'doorkeeper/openid_connect/version'

Gem::Specification.new do |spec|
  spec.name          = 'doorkeeper-openid_connect'
  spec.version       = Doorkeeper::OpenidConnect::VERSION
  spec.authors       = ['Sam Dengler', 'Markus Koller', 'Nikita Bulai']
  spec.email         = ['sam.dengler@playonsports.com', 'markus-koller@gmx.ch', 'bulajnikita@gmail.com']
  spec.homepage      = 'https://github.com/doorkeeper-gem/doorkeeper-openid_connect'
  spec.summary       = 'OpenID Connect extension for Doorkeeper.'
  spec.description   = 'OpenID Connect extension for Doorkeeper.'
  spec.license       = 'MIT'

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "CHANGELOG.md",
    "LICENSE.txt",
    "README.md",
  ]
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_runtime_dependency 'doorkeeper', '>= 5.5', '< 5.9'
  spec.add_runtime_dependency 'jwt', '>= 2.5'

  spec.add_development_dependency 'conventional-changelog', '~> 1.2'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'sqlite3', '>= 1.3.6'
end
