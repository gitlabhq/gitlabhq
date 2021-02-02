# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenWithIv do
  describe 'validations' do
    it { is_expected.to validate_presence_of :hashed_token }
    it { is_expected.to validate_presence_of :iv }
    it { is_expected.to validate_presence_of :hashed_plaintext_token }
  end

  describe '.find_by_hashed_token' do
    it 'only includes matching record' do
      matching_record = create(:token_with_iv, hashed_token: ::Digest::SHA256.digest('hashed-token'))
      create(:token_with_iv)

      expect(described_class.find_by_hashed_token('hashed-token')).to eq(matching_record)
    end
  end

  describe '.find_by_plaintext_token' do
    it 'only includes matching record' do
      matching_record = create(:token_with_iv, hashed_plaintext_token: ::Digest::SHA256.digest('hashed-token'))
      create(:token_with_iv)

      expect(described_class.find_by_plaintext_token('hashed-token')).to eq(matching_record)
    end
  end
end
