# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::SourceIdentifier, feature_category: :importers do
  describe '.hash' do
    it 'returns a hashed value for a present string' do
      expect(described_class.hash('github.com/gitlab-org/gitlab')).to be_a(String)
    end

    it 'returns the same hash for the same value' do
      value = 'github.com/gitlab-org/gitlab'
      first_hash = described_class.hash(value)

      expect(described_class.hash(value)).to eq(first_hash)
    end

    it 'returns different hashes for different values' do
      expect(described_class.hash('github.com/foo/bar')).not_to eq(described_class.hash('github.com/baz/qux'))
    end

    it 'returns nil for a blank value' do
      expect(described_class.hash('')).to be_nil
    end

    it 'returns nil for nil' do
      expect(described_class.hash(nil)).to be_nil
    end
  end
end
