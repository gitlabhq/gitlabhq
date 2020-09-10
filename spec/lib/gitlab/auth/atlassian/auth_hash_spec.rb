# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Atlassian::AuthHash do
  let(:auth_hash) do
    described_class.new(
      OmniAuth::AuthHash.new(uid: 'john', credentials: credentials)
    )
  end

  let(:credentials) do
    {
      token: 'super_secret_token',
      refresh_token: 'super_secret_refresh_token',
      expires_at: 2.weeks.from_now.to_i,
      expires: true
    }
  end

  describe '#uid' do
    it 'returns the correct uid' do
      expect(auth_hash.uid).to eq('john')
    end
  end

  describe '#token' do
    it 'returns the correct token' do
      expect(auth_hash.token).to eq(credentials[:token])
    end
  end

  describe '#refresh_token' do
    it 'returns the correct refresh token' do
      expect(auth_hash.refresh_token).to eq(credentials[:refresh_token])
    end
  end

  describe '#token' do
    it 'returns the correct expires boolean' do
      expect(auth_hash.expires?).to eq(credentials[:expires])
    end
  end

  describe '#token' do
    it 'returns the correct expiration' do
      expect(auth_hash.expires_at).to eq(credentials[:expires_at])
    end
  end
end
