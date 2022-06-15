# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HashDigest::Facade do
  describe '.hexdigest' do
    let(:plaintext) { 'something that is plaintext' }

    let(:sha256_hash) { OpenSSL::Digest::SHA256.hexdigest(plaintext) }
    let(:md5_hash) { Digest::MD5.hexdigest(plaintext) } # rubocop:disable Fips/MD5

    it 'uses SHA256' do
      expect(described_class.hexdigest(plaintext)).to eq(sha256_hash)
    end

    context 'when feature flags is not available' do
      before do
        allow(Feature).to receive(:feature_flags_available?).and_return(false)
      end

      it 'uses MD5' do
        expect(described_class.hexdigest(plaintext)).to eq(md5_hash)
      end
    end

    context 'when active_support_hash_digest_sha256 FF is disabled' do
      before do
        stub_feature_flags(active_support_hash_digest_sha256: false)
      end

      it 'uses MD5' do
        expect(described_class.hexdigest(plaintext)).to eq(md5_hash)
      end
    end
  end
end
