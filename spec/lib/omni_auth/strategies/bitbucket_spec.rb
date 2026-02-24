# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

RSpec.describe OmniAuth::Strategies::Bitbucket do
  subject(:strategy) { described_class.new({}) }

  let(:raw_info) do
    {
      display_name: 'display_name',
      username: 'username',
      uuid: "{#{SecureRandom.uuid}}",
      links: {
        avatar: {
          href: 'avatar-href'
        }
      }
    }.deep_stringify_keys
  end

  let(:primary_email) { 'primaryemail@example.com' }

  let(:emails) do
    [
      {
        email: primary_email,
        is_primary: true,
        is_confirmed: true
      }.stringify_keys,
      {
        email: 'secondaryemail@example.com',
        is_primary: false,
        is_confirmed: true
      }.stringify_keys
    ]
  end

  before do
    allow(strategy).to receive(:raw_info).and_return(raw_info)
    allow(strategy).to receive(:emails).and_return(emails)
  end

  describe 'uid' do
    it 'returns Bitbucket user uuid' do
      expect(strategy.uid).to eq(raw_info['uuid'])
    end
  end

  describe 'info' do
    it 'returns Bitbucket user info' do
      expect(strategy.info).to eq(
        {
          name: raw_info['display_name'],
          username: raw_info['username'],
          avatar: raw_info['links']['avatar']['href'],
          email: primary_email
        }
      )
    end
  end

  describe '#callback_url' do
    let(:base_url) { 'https://example.com' }

    context 'when script name is not present' do
      it 'has the correct default callback path' do
        allow(strategy).to receive(:full_host) { base_url }
        allow(strategy).to receive(:script_name).and_return('')
        allow(strategy).to receive(:query_string).and_return('')
        expect(strategy.callback_url).to eq("#{base_url}/users/auth/bitbucket/callback")
      end
    end

    context 'when script name is present' do
      it 'sets the callback path with script_name' do
        allow(strategy).to receive(:full_host) { base_url }
        allow(strategy).to receive(:script_name).and_return('/v1')
        allow(strategy).to receive(:query_string).and_return('')
        expect(strategy.callback_url).to eq("#{base_url}/v1/users/auth/bitbucket/callback")
      end
    end
  end

  describe 'client_options' do
    it 'uses correct URLs for API calls, authorization, and token exchange' do
      expect(strategy.options.client_options).to have_attributes(
        site: 'https://api.bitbucket.org',
        authorize_url: 'https://bitbucket.org/site/oauth2/authorize',
        token_url: 'https://bitbucket.org/site/oauth2/access_token'
      )
    end
  end

  describe '#raw_info' do
    let(:access_token) { instance_double(OAuth2::AccessToken) }

    before do
      allow(strategy).to receive(:raw_info).and_call_original
      allow(strategy).to receive(:access_token).and_return(access_token)
    end

    it 'requests user info from /2.0/user' do
      expect(access_token)
        .to receive(:get)
        .with('/2.0/user')
        .and_return(instance_double(OAuth2::Response, parsed: raw_info))

      expect(strategy.raw_info).to eq(raw_info)
    end
  end

  describe '#emails' do
    let(:access_token) { instance_double(OAuth2::AccessToken) }

    before do
      allow(strategy).to receive(:emails).and_call_original
      allow(strategy).to receive(:access_token).and_return(access_token)
    end

    it 'requests emails from /2.0/user/emails' do
      expect(access_token)
        .to receive(:get)
        .with('/2.0/user/emails')
        .and_return(instance_double(OAuth2::Response, parsed: { 'values' => emails }))

      expect(strategy.emails).to eq(emails)
    end
  end
end
