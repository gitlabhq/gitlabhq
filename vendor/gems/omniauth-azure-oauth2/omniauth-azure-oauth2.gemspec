# -*- encoding: utf-8 -*-
require File.expand_path(File.join('..', 'lib', 'omniauth', 'azure_oauth2', 'version'), __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mark Nadig"]
  gem.email         = ["mark@nadigs.net"]
  gem.description   = %q{An Windows Azure Active Directory OAuth2 strategy for OmniAuth}
  gem.summary       = %q{An Windows Azure Active Directory OAuth2 strategy for OmniAuth}
  gem.homepage      = "https://github.com/KonaTeam/omniauth-azure-oauth2"

  gem.files         =  Dir.glob("lib/**/*.*")
  gem.test_files    =  Dir.glob("spec/**/**/*.*")
  gem.name          = "omniauth-azure-oauth2"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::AzureOauth2::VERSION
  gem.license       = "MIT"

  gem.add_runtime_dependency 'omniauth', '~> 2.0'
  gem.add_dependency 'jwt', ['>= 1.0', '< 3.0']

  gem.add_runtime_dependency 'omniauth-oauth2', '~> 1.4'

  gem.add_development_dependency 'rspec', '>= 2.14.0'
  gem.add_development_dependency 'rake'
end
