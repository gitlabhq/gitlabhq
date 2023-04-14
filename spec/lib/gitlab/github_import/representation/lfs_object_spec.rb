# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::LfsObject do
  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      github_identifiers = {
        oid: 42,
        size: 123456
      }
      other_attributes = { something_else: '_something_else_' }
      lfs_object = described_class.new(github_identifiers.merge(other_attributes))

      expect(lfs_object.github_identifiers).to eq(github_identifiers)
    end
  end
end
