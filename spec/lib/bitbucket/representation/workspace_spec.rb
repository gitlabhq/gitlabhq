# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Representation::Workspace, feature_category: :importers do
  let(:slug) { 'my-workspace' }
  let(:name) { 'My Workspace' }
  let(:uuid) { '{12345678-1234-1234-1234-123456789012}' }
  let(:workspace_object) do
    {
      'workspace' => {
        'slug' => slug,
        'name' => name,
        'uuid' => uuid
      }
    }
  end

  describe '#slug' do
    it 'returns correct value' do
      workspace = described_class.new(workspace_object)

      expect(workspace.slug).to eq(slug)
    end
  end

  describe '#name' do
    it 'returns correct value' do
      workspace = described_class.new(workspace_object)

      expect(workspace.name).to eq(name)
    end
  end

  describe '#uuid' do
    it 'returns correct value' do
      workspace = described_class.new(workspace_object)

      expect(workspace.uuid).to eq(uuid)
    end
  end
end
