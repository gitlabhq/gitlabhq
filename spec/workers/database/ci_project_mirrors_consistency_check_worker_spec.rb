# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::CiProjectMirrorsConsistencyCheckWorker, feature_category: :continuous_integration do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes the consistency check on projects' do
      expect(Database::ConsistencyCheckService).to receive(:new).and_call_original
      expected_result = { batches: 0, matches: 0, mismatches: 0, mismatches_details: [] }
      expect(worker).to receive(:log_extra_metadata_on_done).with(:results, expected_result)
      worker.perform
    end

    context 'when logs should contain the detailed mismatches' do
      let(:first_project) { Project.all.order(:id).limit(1).first }
      let(:missing_project) { Project.all.order(:id).limit(2).last }

      before do
        redis_shared_state_cleanup!
        create_list(:project, 3) # This will also create Ci::ProjectMirror objects
        missing_project.delete

        allow_next_instance_of(Database::ConsistencyCheckService) do |instance|
          allow(instance).to receive(:random_start_id).and_return(Project.first.id)
        end
      end

      it 'reports the differences to the logs' do
        expected_result = {
          batches: 1,
          matches: 2,
          mismatches: 1,
          mismatches_details: [{
            id: missing_project.id,
            source_table: nil,
            target_table: [missing_project.namespace_id, missing_project.organization_id]
          }],
          start_id: first_project.id,
          next_start_id: first_project.id # The batch size > number of projects
        }
        expect(worker).to receive(:log_extra_metadata_on_done).with(:results, expected_result)
        worker.perform
      end

      it 'calls the consistency_fix_service to fix the inconsistencies' do
        expect_next_instance_of(Database::ConsistencyFixService) do |instance|
          expect(instance).to receive(:execute).with(
            ids: [missing_project.id]
          ).and_call_original
        end
        worker.perform
      end
    end

    context 'when a mirror column has drifted from the project' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:project) { create(:project) }
      let_it_be(:other_namespace) { create(:namespace) }
      let_it_be(:other_organization) { create(:organization) }

      let(:synced_columns) { %w[namespace_id organization_id] }

      where(:column, :stale_value) do
        :namespace_id    | lazy { other_namespace.id }
        :organization_id | lazy { other_organization.id }
      end

      with_them do
        before do
          redis_shared_state_cleanup!
          Ci::ProjectMirror.by_project_id(project.id).update_all(column => stale_value)

          allow_next_instance_of(Database::ConsistencyCheckService) do |instance|
            allow(instance).to receive(:random_start_id).and_return(project.id)
          end
        end

        it 'reports the mismatch and schedules a resync' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(
            :results,
            a_hash_including(
              mismatches: 1,
              mismatches_details: [{
                id: project.id,
                source_table: project.attributes.values_at(*synced_columns),
                target_table: project.attributes.merge(column.to_s => stale_value).values_at(*synced_columns)
              }]
            )
          )

          expect { worker.perform }.to change { Projects::SyncEvent.where(project_id: project.id).count }.by(1)
        end
      end
    end
  end
end
