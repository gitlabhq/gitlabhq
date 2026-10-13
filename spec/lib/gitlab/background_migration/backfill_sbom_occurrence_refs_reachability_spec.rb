# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSbomOccurrenceRefsReachability, feature_category: :dependency_management do
  let(:sbom_components) { table(:sbom_components, database: :sec) }
  let(:sbom_occurrences) { table(:sbom_occurrences, database: :sec) }
  let(:tracked_contexts) { table(:security_project_tracked_contexts, database: :sec) }
  let(:occurrence_refs) { table(:sbom_occurrence_refs, database: :sec) }

  let(:project_id) { 1 }
  let(:unknown) { 0 }
  let(:in_use) { 1 }
  let(:not_found) { 2 }

  let!(:main) { create_tracked_context('main', is_default: true) }
  let!(:feature) { create_tracked_context('feature') }

  let!(:in_use_occurrence) { create_occurrence(reachability: in_use) }
  let!(:in_use_main_ref) { create_ref(in_use_occurrence, main) }
  let!(:in_use_feature_ref) { create_ref(in_use_occurrence, feature) }

  let!(:not_found_occurrence) { create_occurrence(reachability: not_found) }
  let!(:not_found_ref) { create_ref(not_found_occurrence, main) }
  let!(:ingested_ref) { create_ref(not_found_occurrence, feature, reachability: unknown) }

  let!(:nil_occurrence) { create_occurrence(reachability: nil) }
  let!(:nil_ref) { create_ref(nil_occurrence, main) }

  let(:migration) do
    described_class.new(
      start_cursor: [occurrence_refs.minimum(:id)],
      end_cursor: [occurrence_refs.maximum(:id)],
      batch_table: :sbom_occurrence_refs,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: SecApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'copies the occurrence reachability onto every ref of the occurrence' do
      migration.perform

      expect(in_use_main_ref.reload.reachability).to eq(in_use)
      expect(in_use_feature_ref.reload.reachability).to eq(in_use)
    end

    it 'gives each ref the reachability of its own occurrence' do
      expect { migration.perform }.to change { not_found_ref.reload.reachability }.from(nil).to(not_found)
    end

    it 'keeps a reachability that ingestion already wrote to the ref, even unknown' do
      expect { migration.perform }.not_to change { ingested_ref.reload.reachability }.from(unknown)
    end

    it 'leaves the ref unset when the occurrence reachability is null' do
      expect { migration.perform }.not_to change { nil_ref.reload.reachability }.from(nil)
    end
  end

  private

  def create_tracked_context(context_name, is_default: false)
    tracked_contexts.create!(
      project_id: project_id,
      context_name: context_name,
      context_type: 1, # branch
      state: 2,        # tracked
      is_default: is_default
    )
  end

  def create_occurrence(reachability:)
    component = sbom_components.create!(
      name: "component-#{SecureRandom.hex(4)}",
      component_type: 0,
      organization_id: 1,
      created_at: Time.current,
      updated_at: Time.current
    )

    sbom_occurrences.create!(
      project_id: project_id,
      component_id: component.id,
      commit_sha: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      reachability: reachability,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  def create_ref(occurrence, tracked_context, reachability: nil)
    occurrence_refs.create!(
      project_id: project_id,
      sbom_occurrence_id: occurrence.id,
      security_project_tracked_context_id: tracked_context.id,
      commit_sha: SecureRandom.hex(20),
      reachability: reachability
    )
  end
end
