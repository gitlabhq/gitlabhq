require 'webmock'
require 'webmock/rspec'

WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ['elasticsearch', 'registry.gitlab.com-gitlab-org-test-elastic-image']
)
