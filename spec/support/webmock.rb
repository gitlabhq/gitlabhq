# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec'

def webmock_allowed_hosts
  %w[elasticsearch registry.gitlab.com-gitlab-org-test-elastic-image].tap do |hosts|
    if ENV.key?('ELASTIC_URL')
      hosts << URI.parse(ENV['ELASTIC_URL']).host
    end
  end.uniq
end

WebMock.disable_net_connect!(allow_localhost: true, allow: webmock_allowed_hosts)
