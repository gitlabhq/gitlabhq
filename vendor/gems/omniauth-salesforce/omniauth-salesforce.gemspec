# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth-salesforce/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Richard Vanhook"]
  gem.email         = ["rvanhook@salesforce.com"]
  gem.description   = %q{OmniAuth strategy for salesforce.com.}
  gem.summary       = %q{OmniAuth strategy for salesforce.com.}
  gem.homepage      = "https://github.com/realdoug/omniauth-salesforce"

  gem.files         =  Dir.glob("lib/**/*.*")
  gem.test_files    =  Dir.glob("spec/**/**/*.*")
  gem.name          = "omniauth-salesforce"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::Salesforce::VERSION
  gem.license       = "MIT"

  gem.add_dependency 'omniauth', '~> 2.0'
  gem.add_dependency 'omniauth-oauth2', '~> 1.0'
  gem.add_development_dependency 'rspec', '~> 3.1'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'webmock'
end
