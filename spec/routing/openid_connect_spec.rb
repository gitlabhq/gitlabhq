# frozen_string_literal: true

require 'spec_helper'

# oauth_discovery_keys      GET /oauth/discovery/keys(.:format)             jwks#keys
# oauth_discovery_provider  GET /.well-known/openid-configuration(.:format) jwks#provider
# oauth_discovery_webfinger GET /.well-known/webfinger(.:format)            jwks#webfinger
RSpec.describe Doorkeeper::OpenidConnect::DiscoveryController, 'routing' do
  it "to #provider" do
    expect(get('/.well-known/openid-configuration')).to route_to('jwks#provider')
  end

  it "to #webfinger" do
    expect(get('/.well-known/webfinger')).to route_to('jwks#webfinger')
  end

  it "to #keys" do
    expect(get('/oauth/discovery/keys')).to route_to('jwks#keys')
  end
end

# oauth_userinfo GET  /oauth/userinfo(.:format) doorkeeper/openid_connect/userinfo#show
#                POST /oauth/userinfo(.:format) doorkeeper/openid_connect/userinfo#show
RSpec.describe Doorkeeper::OpenidConnect::UserinfoController, 'routing' do
  it "to #show" do
    expect(get('/oauth/userinfo')).to route_to('doorkeeper/openid_connect/userinfo#show')
  end

  it "to #show" do
    expect(post('/oauth/userinfo')).to route_to('doorkeeper/openid_connect/userinfo#show')
  end
end
