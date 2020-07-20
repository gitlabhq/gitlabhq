# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::BundleFile do
  describe '.check!' do
    let(:valid_bundle) { Tempfile.new }
    let(:valid_bundle_path) { valid_bundle.path }
    let(:invalid_bundle_path) { Rails.root.join('spec/fixtures/malicious.bundle') }

    after do
      valid_bundle.close!
    end

    it 'returns nil for a valid bundle' do
      valid_bundle.write("# v2 git bundle\nfoo bar baz\n")
      valid_bundle.close

      expect(described_class.check!(valid_bundle_path)).to be_nil
    end

    it 'raises an exception for an invalid bundle' do
      expect do
        described_class.check!(invalid_bundle_path)
      end.to raise_error(described_class::InvalidBundleError)
    end
  end
end
