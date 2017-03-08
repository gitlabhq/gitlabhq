require 'webmock'
require 'webmock/rspec'

allowed = %w[elasticsearch registry.gitlab.com-gitlab-org-test-elastic-image]

if ENV.has_key?('ELASTIC_URL')
  url = URI.parse(ENV['ELASTIC_URL'])
  allowed << url.host
  allowed.uniq!
end

WebMock.disable_net_connect!(allow_localhost: true, allow: allowed)
