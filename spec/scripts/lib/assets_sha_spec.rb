# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/all'

require_relative '../../../scripts/lib/assets_sha'

RSpec.describe AssetsSha, feature_category: :tooling do
  include StubENV

  describe '.sha256_of_assets_impacting_compilation' do
    before do
      # Stub the file list so the digest does not depend on the whole working tree;
      # the behaviour under test is how the env-derived suffix changes the digest.
      allow(described_class).to receive(:assets_impacting_compilation).and_return([])
    end

    it 'returns a SHA256 hexdigest' do
      stub_env('ENABLE_RSPACK', '')

      expect(described_class.sha256_of_assets_impacting_compilation).to match(/\A[0-9a-f]{64}\z/)
    end

    it 'incorporates ENABLE_RSPACK so Rspack and Webpack builds get distinct cache keys' do
      stub_env('ENABLE_RSPACK', '')
      without_rspack = described_class.sha256_of_assets_impacting_compilation

      stub_env('ENABLE_RSPACK', 'true')
      with_rspack = described_class.sha256_of_assets_impacting_compilation

      expect(with_rspack).not_to eq(without_rspack)
    end
  end
end
