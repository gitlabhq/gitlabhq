# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec'

def webmock_allowed_hosts
  %w[elasticsearch registry.gitlab.com-gitlab-org-test-elastic-image].tap do |hosts|
    if ENV.key?('ELASTIC_URL')
      hosts << URI.parse(ENV['ELASTIC_URL']).host
    end

    if ENV.key?('ZOEKT_INDEX_BASE_URL')
      hosts.concat(allowed_host_and_ip(ENV['ZOEKT_INDEX_BASE_URL']))
    end

    if ENV.key?('ZOEKT_SEARCH_BASE_URL')
      hosts.concat(allowed_host_and_ip(ENV['ZOEKT_SEARCH_BASE_URL']))
    end

    if Gitlab.config.webpack&.dev_server&.enabled
      hosts << Gitlab.config.webpack.dev_server.host
    end
  end.compact.uniq
end

def allowed_host_and_ip(url)
  host = URI.parse(url).host
  ip_address = Addrinfo.ip(host).ip_address
  [host, ip_address]
end

def with_net_connect_allowed
  WebMock.allow_net_connect!
  yield
ensure
  webmock_enable!
end

# This prevents Selenium/WebMock from spawning thousands of connections
# while waiting for an element to appear via Capybara's find:
# https://github.com/teamcapybara/capybara/issues/2322#issuecomment-619321520
def webmock_enable_with_http_connect_on_start!
  webmock_enable!(net_http_connect_on_start: true)
end

def webmock_enable!(options = {})
  WebMock.disable_net_connect!(
    {
      allow_localhost: true,
      allow: webmock_allowed_hosts
    }.merge(options)
  )
end

webmock_enable!
