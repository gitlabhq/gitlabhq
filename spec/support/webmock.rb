require 'webmock'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true, allow: 'elasticsearch')
WebMock.disable_net_connect!(allow_localhost: true, allow: 'registry.gitlab.com__gitlab-org__test-elastic-image')
