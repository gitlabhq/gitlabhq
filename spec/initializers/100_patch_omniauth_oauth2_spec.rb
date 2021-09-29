# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth::Strategies::OAuth2', type: :strategy do
  let(:strategy) { [OmniAuth::Strategies::OAuth2] }

  it 'verifies the gem version' do
    current_version = OmniAuth::OAuth2::VERSION
    expected_version = '1.7.1'

    expect(current_version).to eq(expected_version), <<~EOF
      New version #{current_version} of the `omniauth-oauth2` gem detected!

      Please check if the monkey patches in `config/initializers_before_autoloader/100_patch_omniauth_oauth2.rb`
      are still needed, and either update/remove them, or bump the version in this spec.

    EOF
  end

  context 'when a custom error message is passed from an OAuth2 provider' do
    let(:message) { 'Please go to https://evil.com' }
    let(:state) { 'secret' }
    let(:callback_path) { '/users/auth/oauth2/callback' }
    let(:params) { { state: state, error: 'evil_key', error_description: message } }
    let(:error) { last_request.env['omniauth.error'] }

    before do
      env('rack.session', { 'omniauth.state' => state })
    end

    it 'returns the custom error message if the state is valid' do
      get callback_path, **params

      expect(error.message).to eq("evil_key | #{message}")
    end

    it 'returns the custom `error_reason` message if the `error_description` is blank' do
      get callback_path, **params.merge(error_description: ' ', error_reason: 'custom reason')

      expect(error.message).to eq('evil_key | custom reason')
    end

    it 'returns a CSRF error if the state is invalid' do
      get callback_path, **params.merge(state: 'invalid')

      expect(error.message).to eq('csrf_detected | CSRF detected')
    end

    it 'returns a CSRF error if the state is missing' do
      get callback_path, **params.without(:state)

      expect(error.message).to eq('csrf_detected | CSRF detected')
    end
  end
end
