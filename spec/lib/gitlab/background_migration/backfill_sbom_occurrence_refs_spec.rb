# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSbomOccurrenceRefs, feature_category: :dependency_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:sbom_components) { table(:sbom_components, database: :sec) }
  let(:sbom_occurrences) { table(:sbom_occurrences, database: :sec) }
  let(:tracked_contexts) { table(:security_project_tracked_contexts, database: :sec) }
  let(:occurrence_refs) { table(:sbom_occurrence_refs, database: :sec) }

  let(:now) { Time.current }

  let(:migration) do
    described_class.new(
      start_cursor: [sbom_occurrences.minimum(:id)],
      end_cursor: [sbom_occurrences.maximum(:id)],
      batch_table: :sbom_occurrences,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: SecApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'when a project has a single default-branch context' do
      let!(:project) { create_project(path: 'single-default') }
      let!(:default_context) { create_tracked_context(project.id, 'main', is_default: true) }
      let!(:occurrence) { create_occurrence(project.id, pipeline_id: 100) }

      it 'creates a ref pointing to the default-branch context', :aggregate_failures do
        expect { migration.perform }.to change { occurrence_refs.count }.by(1)

        ref = occurrence_refs.last
        expect(ref.sbom_occurrence_id).to eq(occurrence.id)
        expect(ref.security_project_tracked_context_id).to eq(default_context.id)
        expect(ref.project_id).to eq(project.id)
        expect(ref.pipeline_id).to eq(100)
      end

      it 'does not call Gitaly' do
        expect(described_class::Project).not_to receive(:where)

        migration.perform
      end

      it 'is idempotent' do
        migration.perform

        expect { migration.perform }.not_to change { occurrence_refs.count }
      end
    end

    context 'when a project has no default-branch context' do
      let!(:project) { create_project(path: 'no-default') }
      let!(:occurrence) { create_occurrence(project.id) }

      it 'skips the occurrence' do
        expect { migration.perform }.not_to change { occurrence_refs.count }
      end
    end

    context 'when a project has multiple default-branch contexts (old bug)' do
      let!(:project) { create_project(path: 'multi-default') }
      let!(:correct_context) { create_tracked_context(project.id, 'main', is_default: true) }
      let!(:stale_context) { create_tracked_context(project.id, 'old-default', is_default: true) }
      let!(:occurrence) { create_occurrence(project.id) }

      before do
        allow_next_instance_of(described_class::Project) do |instance|
          allow(instance).to receive(:default_branch).and_return('main')
        end
      end

      it 'resolves the real default branch via Gitaly and picks the matching context' do
        expect { migration.perform }.to change { occurrence_refs.count }.by(1)

        expect(occurrence_refs.last.security_project_tracked_context_id).to eq(correct_context.id)
      end

      context 'when Gitaly cannot resolve the default branch' do
        before do
          allow_next_instance_of(described_class::Project) do |instance|
            allow(instance).to receive(:default_branch).and_return(nil)
          end
        end

        it 'falls back to the lowest context id' do
          expect { migration.perform }.to change { occurrence_refs.count }.by(1)

          expect(occurrence_refs.last.security_project_tracked_context_id)
            .to eq([correct_context.id, stale_context.id].min)
        end
      end
    end
  end

  private

  def create_project(**attributes)
    attributes[:name] ||= attributes[:path]

    organization = organizations.create!(name: attributes[:name], path: attributes[:path])
    namespace = namespaces.create!(
      name: attributes[:name],
      path: attributes[:path],
      organization_id: organization.id
    )

    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id,
      storage_version: 1,
      **attributes
    )
  end

  def create_tracked_context(project_id, context_name, is_default: false)
    tracked_contexts.create!(
      project_id: project_id,
      context_name: context_name,
      context_type: 1, # branch
      state: 2,        # tracked
      is_default: is_default
    )
  end

  def create_occurrence(project_id, pipeline_id: nil)
    component = sbom_components.create!(
      name: "component-#{SecureRandom.hex(4)}",
      component_type: 0,
      organization_id: 1,
      created_at: now,
      updated_at: now
    )

    sbom_occurrences.create!(
      project_id: project_id,
      component_id: component.id,
      pipeline_id: pipeline_id,
      commit_sha: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      created_at: now,
      updated_at: now
    )
  end
end
