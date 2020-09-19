# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::Identity do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { create(:atlassian_identity) }

    it { is_expected.to validate_presence_of(:extern_uid) }
    it { is_expected.to validate_uniqueness_of(:extern_uid) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_uniqueness_of(:user) }
  end

  describe 'encrypted tokens' do
    let(:token) { SecureRandom.alphanumeric(1254) }
    let(:refresh_token) { SecureRandom.alphanumeric(45) }
    let(:identity) { create(:atlassian_identity, token: token, refresh_token: refresh_token) }

    it 'saves the encrypted token, refresh token and corresponding ivs' do
      expect(identity.encrypted_token).not_to be_nil
      expect(identity.encrypted_token_iv).not_to be_nil
      expect(identity.encrypted_refresh_token).not_to be_nil
      expect(identity.encrypted_refresh_token_iv).not_to be_nil

      expect(identity.token).to eq(token)
      expect(identity.refresh_token).to eq(refresh_token)
    end
  end
end
