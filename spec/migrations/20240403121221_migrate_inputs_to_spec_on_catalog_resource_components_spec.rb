# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateInputsToSpecOnCatalogResourceComponents, feature_category: :pipeline_composition do
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:resources_table) { table(:catalog_resources) }
  let(:releases_table) { table(:releases) }
  let(:versions_table) { table(:catalog_resource_versions) }
  let(:components_table) { table(:catalog_resource_components) }

  it 'fills in the spec column for components with an inputs value and no spec value', :aggregate_failures do
    namespace = namespaces_table.create!(name: 'test', path: 'test')
    project = projects_table.create!(namespace_id: namespace.id, project_namespace_id: namespace.id)
    resource = resources_table.create!(project_id: project.id)
    release = releases_table.create!(released_at: Time.current, tag: 'test')
    version = versions_table.create!(release_id: release.id, catalog_resource_id: resource.id, project_id: project.id)

    component_needs_spec = components_table.create!(
      name: 'test', inputs: { test_input: nil }, spec: {},
      version_id: version.id, project_id: project.id, catalog_resource_id: resource.id
    )
    component_has_spec = components_table.create!(
      name: 'test', spec: { inputs: { test_input: nil } }, inputs: {},
      version_id: version.id, project_id: project.id, catalog_resource_id: resource.id
    )
    component_no_spec = components_table.create!(
      name: 'test', spec: {}, inputs: {},
      version_id: version.id, project_id: project.id, catalog_resource_id: resource.id
    )

    migrate!

    expect(component_needs_spec.reload.spec).to eq({ 'inputs' => { 'test_input' => nil } })
    expect(component_has_spec.reload.spec).to eq({ 'inputs' => { 'test_input' => nil } })
    expect(component_no_spec.reload.spec).to be_empty
  end
end
