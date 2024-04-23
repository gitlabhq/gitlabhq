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
end
