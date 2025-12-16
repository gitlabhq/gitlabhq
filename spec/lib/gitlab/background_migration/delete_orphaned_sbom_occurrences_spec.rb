# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedSbomOccurrences,
  feature_category: :dependency_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:sbom_components) { table(:sbom_components, database: :sec) }
  let(:sbom_component_versions) { table(:sbom_component_versions, database: :sec) }
  let(:sbom_sources) { table(:sbom_sources, database: :sec) }
  let(:sbom_occurrences) { table(:sbom_occurrences, database: :sec) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let!(:namespace) do
    namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:component) do
    sbom_components.create!(
      component_type: 0,
      name: 'test-component',
      purl_type: 1,
      organization_id: organization.id
    )
  end

  let!(:component_version) do
    sbom_component_versions.create!(
      component_id: component.id,
      version: '1.0.0',
      organization_id: organization.id
    )
  end

  let!(:source) do
    sbom_sources.create!(
      source_type: 0,
      organization_id: organization.id
    )
  end

  let!(:valid_occurrence) do
    sbom_occurrences.create!(
      project_id: project.id,
      component_id: component.id,
      component_version_id: component_version.id,
      source_id: source.id,
      commit_sha: 'abc123',
      uuid: SecureRandom.uuid,
      component_name: 'test-component'
    )
  end

  let!(:orphaned_occurrence_1) do
    sbom_occurrences.create!(
      project_id: non_existing_record_id,
      component_id: component.id,
      component_version_id: component_version.id,
      source_id: source.id,
      commit_sha: 'def456',
      uuid: SecureRandom.uuid,
      component_name: 'orphaned-component-1'
    )
  end

  let!(:orphaned_occurrence_2) do
    sbom_occurrences.create!(
      project_id: non_existing_record_id - 1,
      component_id: component.id,
      component_version_id: component_version.id,
      source_id: source.id,
      commit_sha: 'ghi789',
      uuid: SecureRandom.uuid,
      component_name: 'orphaned-component-2'
    )
  end

  let(:starting_id) { sbom_occurrences.minimum(:id) }
  let(:end_id) { sbom_occurrences.maximum(:id) }

  let(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :sbom_occurrences,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: SecApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'deletes orphaned sbom_occurrences but keeps valid ones', :aggregate_failures do
      expect { migration.perform }.to change { sbom_occurrences.count }.from(3).to(1)
      expect(sbom_occurrences.exists?(valid_occurrence.id)).to be(true)
      expect(sbom_occurrences.exists?(orphaned_occurrence_1.id)).to be(false)
      expect(sbom_occurrences.exists?(orphaned_occurrence_2.id)).to be(false)
    end

    context 'when there are no orphaned occurrences' do
      before do
        sbom_occurrences.where(id: [orphaned_occurrence_1.id, orphaned_occurrence_2.id]).delete_all
      end

      it 'does not delete anything' do
        expect { migration.perform }.not_to change { sbom_occurrences.count }.from(1)
      end
    end
  end
end
