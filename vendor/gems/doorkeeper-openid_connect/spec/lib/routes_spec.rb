# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::Rails::Routes, type: :routing do
  describe 'userinfo' do
    it 'maps GET #show' do
      expect(get: 'oauth/userinfo').to route_to(
        controller: 'doorkeeper/openid_connect/userinfo',
        action: 'show'
      )
    end

    it 'maps POST #show' do
      expect(post: 'oauth/userinfo').to route_to(
        controller: 'doorkeeper/openid_connect/userinfo',
        action: 'show'
      )
    end
  end

  describe 'discovery' do
    it 'maps GET #provider' do
      expect(get: '.well-known/openid-configuration').to route_to(
        controller: 'doorkeeper/openid_connect/discovery',
        action: 'provider'
      )
    end

    it 'maps GET #webfinger' do
      expect(get: '.well-known/webfinger').to route_to(
        controller: 'doorkeeper/openid_connect/discovery',
        action: 'webfinger'
      )
    end

    it 'maps GET #keys' do
      expect(get: 'oauth/discovery/keys').to route_to(
        controller: 'doorkeeper/openid_connect/discovery',
        action: 'keys'
      )
    end
  end
end
