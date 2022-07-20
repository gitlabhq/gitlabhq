require 'bundler/setup'
Bundler.setup
require 'rack/test'
require 'webmock'
require 'webmock/rspec'
require 'nokogiri'

require 'omniauth_crowd'
RSpec.configure do |config|
  WebMock.disable_net_connect!
  config.include Rack::Test::Methods
  config.raise_errors_for_deprecations!
end

