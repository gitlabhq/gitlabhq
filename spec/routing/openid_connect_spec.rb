# frozen_string_literal: true

require 'spec_helper'

# oauth_discovery_keys      GET /oauth/discovery/keys(.:format)             jwks#keys
# oauth_discovery_provider  GET /.well-known/openid-configuration(.:format) jwks#provider
# oauth_discovery_webfinger GET /.well-known/webfinger(.:format)            jwks#webfinger
RSpec.describe Doorkeeper::OpenidConnect::DiscoveryController, 'routing' do
  specify "to #provider" do
    expect(get('/.well-known/openid-configuration')).to route_to('jwks#provider')
  end

  specify "to #webfinger" do
    expect(get('/.well-known/webfinger')).to route_to('jwks#webfinger')
  end

  specify "to #keys" do
    expect(get('/oauth/discovery/keys')).to route_to('jwks#keys')
  end
end

# oauth_userinfo GET  /oauth/userinfo(.:format) oauth/userinfo#show
#                POST /oauth/userinfo(.:format) oauth/userinfo#show
RSpec.describe Oauth::UserinfoController, 'routing', feature_category: :system_access do
  specify "to #show" do
    expect(get('/oauth/userinfo')).to route_to('oauth/userinfo#show')
  end

  specify "to #show" do
    expect(post('/oauth/userinfo')).to route_to('oauth/userinfo#show')
  end
end
