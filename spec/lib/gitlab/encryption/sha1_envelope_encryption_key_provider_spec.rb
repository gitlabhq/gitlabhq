# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Encryption::Sha1EnvelopeEncryptionKeyProvider, feature_category: :system_access do
  describe '#encryption_key' do
    it 'uses SHA1 hash digest class for key generation' do
      provider = described_class.new

      # rubocop:disable Fips/SHA1 -- Intentionally testing SHA1 compatibility for backward compatibility
      expect(ActiveRecord::Encryption::KeyGenerator).to receive(:new)
        .with(hash_digest_class: OpenSSL::Digest::SHA1)
        .and_call_original
      # rubocop:enable Fips/SHA1

      provider.encryption_key
    end
  end
end
