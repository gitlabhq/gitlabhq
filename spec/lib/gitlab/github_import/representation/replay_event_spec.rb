# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::ReplayEvent, feature_category: :importers do
  describe '.from_json_hash' do
    it 'returns an instance of ReplayEvent' do
      representation = described_class.from_json_hash(issuable_iid: 1, issuable_type: 'MergeRequest')

      expect(representation).to be_an_instance_of(described_class)
    end
  end

  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      representation = described_class.new(issuable_type: 'MergeRequest', issuable_iid: 1)

      expect(representation.github_identifiers).to eq({
        issuable_type: 'MergeRequest',
        issuable_iid: 1
      })
    end
  end
end
