# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::LfsObject, feature_category: :importers do
  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      github_identifiers = {
        oid: 42,
        size: 123456
      }
      other_attributes = { headers: { Authorization: 'RemoteAuth 123456' } }
      lfs_object = described_class.new(github_identifiers.merge(other_attributes))

      expect(lfs_object.github_identifiers).to eq(github_identifiers)
      expect(lfs_object.headers).to eq({ Authorization: 'RemoteAuth 123456' })
    end
  end
end
