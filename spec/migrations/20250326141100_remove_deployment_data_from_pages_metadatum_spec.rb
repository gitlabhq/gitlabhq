# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDeploymentDataFromPagesMetadatum, migration: :gitlab_main, feature_category: :pages do
  let(:migration) { described_class.new }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }

  let(:project) do
    table(:projects).create!(
      name: 'test-project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:project_pages_metadatum) do
    table(:project_pages_metadata).create!(
      project_id: project.id,
      onboarding_complete: true,
      deployed: false,
      pages_deployment_id: nil
    )
  end

  it 'performs a reversible migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(project_pages_metadatum).to have_attributes(
          {
            'project_id' => project.id,
            'onboarding_complete' => true,
            'deployed' => false,
            'pages_deployment_id' => nil
          }
        )
      }

      migration.after -> {
        expect(project_pages_metadatum).to have_attributes(
          {
            'project_id' => project.id,
            'onboarding_complete' => true
          }
        )
      }
    end
  end
end
