# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth::Strategies::SAML', type: :strategy do
  let(:idp_sso_target_url) { 'https://login.example.com/idp' }
  let(:strategy) { [OmniAuth::Strategies::SAML, { idp_sso_target_url: idp_sso_target_url }] }
  let(:base_url) { 'https://example.com' }
  let(:callback_path) { '/users/auth/saml/callback' }

  before do
    mock_session = {}

    allow(mock_session).to receive(:enabled?).and_return(true)
    allow(mock_session).to receive(:loaded?).and_return(true)

    env('rack.session', mock_session)
  end

  describe 'POST /users/auth/saml' do
    it 'redirects to the provider login page', :aggregate_failures do
      post '/users/auth/saml'

      expect(last_response.status).to eq(302)
      expect(last_response.location).to match(/\A#{Regexp.quote(idp_sso_target_url)}/)
    end

    it 'stores request ID during request phase' do
      request_id = double
      allow_next_instance_of(OneLogin::RubySaml::Authrequest) do |instance|
        allow(instance).to receive(:uuid).and_return(request_id)
      end

      post '/users/auth/saml'
      expect(session['last_authn_request_id']).to eq(request_id)
    end
  end

  describe 'callback_url option' do
    it 'creates callback_url from the full_host and callback_path' do
      strategy = OmniAuth::Strategies::SAML.new({})

      allow(strategy).to receive(:full_host).and_return(base_url)
      allow(strategy).to receive(:callback_path).and_return(callback_path)
      allow(strategy).to receive(:query_string)
        .and_return('?redirect_to=/twitter/Typeahead.Js/-/merge_requests/2/saml_approval')

      expect(strategy.callback_url).to eq(base_url + callback_path)
    end
  end

  describe 'assertion_consumer_service_url setting' do
    it 'is built from the full_host and callback_path' do
      strategy = OmniAuth::Strategies::SAML.new({})

      allow(strategy).to receive(:full_host).and_return(base_url)
      allow(strategy).to receive(:callback_path).and_return(callback_path)
      allow(strategy).to receive(:query_string)
        .and_return('?redirect_to=/twitter/Typeahead.Js/-/merge_requests/2/saml_approval')

      expect(strategy.callback_url).to eq(base_url + callback_path)

      strategy.send(:with_settings) do |settings|
        expect(settings.assertion_consumer_service_url).to eq(base_url + callback_path)
      end
    end
  end
end
