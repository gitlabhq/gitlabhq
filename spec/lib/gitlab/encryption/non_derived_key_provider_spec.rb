# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Encryption::NonDerivedKeyProvider, feature_category: :shared do
  describe 'inheritance' do
    it 'inherits from ActiveRecord::Encryption::KeyProvider' do
      expect(described_class.superclass).to be(ActiveRecord::Encryption::KeyProvider)
    end
  end

  describe '#initialize' do
    let(:secrets) { Settings.db_key_base_keys }

    subject(:service) { described_class.new(secrets) }

    it 'instantiate ActiveRecord::Encryption::Key keys' do
      provider_keys = service.decryption_keys(ActiveRecord::Encryption::Message.new)

      expect(provider_keys)
        .to all(be_a(ActiveRecord::Encryption::Key))
    end

    it 'returns all keys by default' do
      expect(service.decryption_keys(ActiveRecord::Encryption::Message.new).map(&:secret))
        .to eq(secrets)
    end
  end
end
