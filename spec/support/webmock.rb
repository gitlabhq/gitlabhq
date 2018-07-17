require 'webmock'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true, allow: %r{https://\w+.ngrok.io/})
