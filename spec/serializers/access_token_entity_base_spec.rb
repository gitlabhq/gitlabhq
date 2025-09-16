# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessTokenEntityBase do
  let_it_be(:user) { create(:user) }
  let_it_be(:token) { create(:personal_access_token, user: user) }

  subject(:json) { described_class.new(token).as_json }

  it 'has the correct attributes' do
    expect(json).to(
      include(
        id: token.id,
        name: token.name,
        description: token.description,
        revoked: false,
        created_at: token.created_at,
        scopes: token.scopes,
        expires_at: token.expires_at.iso8601,
        last_used_ips: token.last_used_ips,
        expired: false,
        expires_soon: false
      ))

    expect(json).not_to include(:token)
  end

  context 'when token has no Last Used IPs' do
    before do
      token.last_used_ips.delete_all
    end

    it 'returns an empty array' do
      expect(json[:last_used_ips]).to eq([])
    end
  end

  context 'when token has last_used_ips' do
    let(:current_ip_address) { '127.0.0.1' }

    before do
      token.last_used_ips << Authn::PersonalAccessTokenLastUsedIp.new(
        organization: token.organization,
        ip_address: current_ip_address)
    end

    it 'returns an array containing current_ip_address' do
      expect(json[:last_used_ips]).to include(current_ip_address)
    end
  end
end
