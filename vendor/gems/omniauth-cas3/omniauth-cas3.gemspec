# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth/cas3/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Derek Lindahl, tduehr"]
  gem.email         = ["td@matasano.com"]
  gem.summary       = %q{CAS 3.0 Strategy for OmniAuth}
  gem.description   = gem.summary
  gem.homepage      = "https://github.com/tduehr/omniauth-cas3"

  gem.files         = Dir.glob("lib/**/*.*")
  gem.test_files    = Dir.glob("spec/**/**/*.*")
  gem.name          = "omniauth-cas3"
  gem.require_paths = ["lib"]
  gem.version       = Omniauth::Cas3::VERSION

  gem.add_dependency 'omniauth',                '~> 2.0'
  gem.add_dependency 'nokogiri',                '~> 1.7', '>= 1.7.1'
  gem.add_dependency 'addressable',             '~> 2.3'

  gem.add_development_dependency 'rake',        '~> 10.0'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'rspec',       '>= 3.4'
  gem.add_development_dependency 'rack-test',   '~> 0.6'

  gem.add_development_dependency 'awesome_print'
end
