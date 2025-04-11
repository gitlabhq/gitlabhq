# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Encryption::KeyProviderWrapper, feature_category: :shared do
  let(:key_provider) { instance_double(ActiveRecord::Encryption::KeyProvider) }

  subject(:wrapper) { described_class.new(key_provider) }

  describe '#encryption_key' do
    it 'delegates to key_provider' do
      expect(key_provider).to receive(:encryption_key)

      wrapper.encryption_key
    end
  end

  describe '#decryption_keys' do
    it 'delegates to key_provider' do
      expect(key_provider).to receive(:decryption_keys).with(ActiveRecord::Encryption::Message.new)

      wrapper.decryption_keys
    end
  end
end
