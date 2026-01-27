# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authz::PermissionGroups::Resource, feature_category: :permissions do
  describe '.config_path' do
    it 'returns the glob pattern for metadata files' do
      expect(described_class.config_path).to include('**/_metadata.yml')
    end
  end

  describe '.all' do
    it 'loads all resources with hierarchical identifiers' do
      resources = described_class.all
      first_key = resources.each_key.first

      expect(resources).not_to be_empty
      expect(first_key).to be_a(Symbol)
      expect(first_key.to_s).to include('/')
    end
  end

  describe '.get' do
    it 'retrieves a resource by hierarchical identifier' do
      resource = described_class.get(:"ci_cd/pipeline")

      expect(resource).to be_present
      expect(resource.definition).to have_key(:description)
    end

    it 'returns nil for non-existent resource' do
      resource = described_class.get(:"nonexistent/resource")

      expect(resource).to be_nil
    end
  end

  describe 'instance methods' do
    let(:definition) { { description: 'Test resource' } }
    let(:file_path) { "config/authz/permission_groups/assignable_permissions/ci_cd/pipeline/_metadata.yml" }

    subject(:resource) { described_class.new(definition, file_path) }

    describe '#description' do
      it 'returns the definition description' do
        expect(resource.description).to eq(definition[:description])
      end
    end
  end
end
