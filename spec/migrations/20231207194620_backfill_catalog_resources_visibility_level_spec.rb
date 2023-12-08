# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillCatalogResourcesVisibilityLevel, feature_category: :pipeline_composition do
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }

  let(:project) do
    table(:projects).create!(
      visibility_level: Gitlab::VisibilityLevel::INTERNAL,
      namespace_id: namespace.id, project_namespace_id: namespace.id
    )
  end

  let(:resource) { table(:catalog_resources).create!(project_id: project.id) }

  describe '#up' do
    it 'updates the visibility_level to match the project' do
      expect(resource.visibility_level).to eq(0)

      migrate!

      expect(resource.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end
  end
end
