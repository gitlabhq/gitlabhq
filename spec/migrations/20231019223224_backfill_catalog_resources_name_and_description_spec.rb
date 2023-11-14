# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillCatalogResourcesNameAndDescription, feature_category: :pipeline_composition do
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }

  let(:project) do
    table(:projects).create!(
      name: 'My project name', description: 'My description',
      namespace_id: namespace.id, project_namespace_id: namespace.id
    )
  end

  let(:resource) { table(:catalog_resources).create!(project_id: project.id) }

  describe '#up' do
    it 'updates the name and description to match the project' do
      expect(resource.name).to be_nil
      expect(resource.description).to be_nil

      migrate!

      expect(resource.reload.name).to eq(project.name)
      expect(resource.reload.description).to eq(project.description)
    end
  end
end
