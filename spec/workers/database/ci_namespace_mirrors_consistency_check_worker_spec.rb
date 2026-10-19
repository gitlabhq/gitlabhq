# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::CiNamespaceMirrorsConsistencyCheckWorker, feature_category: :continuous_integration do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes the consistency check on namespaces' do
      expect(Database::ConsistencyCheckService).to receive(:new).and_call_original
      expected_result = { batches: 0, matches: 0, mismatches: 0, mismatches_details: [] }
      expect(worker).to receive(:log_extra_metadata_on_done).with(:results, expected_result)
      worker.perform
    end

    context 'when logs should contain the detailed mismatches' do
      let(:first_namespace) { Namespace.all.order(:id).limit(1).first }
      let(:missing_namespace) { Namespace.all.order(:id).limit(2).last }

      before do
        redis_shared_state_cleanup!
        create_list(:namespace, 3) # This will also create Ci::NameSpaceMirror objects
        missing_namespace.delete

        allow_next_instance_of(Database::ConsistencyCheckService) do |instance|
          allow(instance).to receive(:random_start_id).and_return(Namespace.first.id)
        end
      end

      it 'reports the differences to the logs' do
        expected_result = {
          batches: 1,
          matches: 2,
          mismatches: 1,
          mismatches_details: [{
            id: missing_namespace.id,
            source_table: nil,
            target_table: [missing_namespace.traversal_ids, missing_namespace.organization_id]
          }],
          start_id: first_namespace.id,
          next_start_id: first_namespace.id # The batch size > number of namespaces
        }
        expect(worker).to receive(:log_extra_metadata_on_done).with(:results, expected_result)
        worker.perform
      end

      it 'calls the consistency_fix_service to fix the inconsistencies' do
        allow_next_instance_of(Database::ConsistencyFixService) do |instance|
          expect(instance).to receive(:execute).with(
            ids: [missing_namespace.id]
          ).and_call_original
        end
        worker.perform
      end
    end

    context 'when a mirror column has drifted from the namespace' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:namespace) { create(:namespace) }
      let_it_be(:other_organization) { create(:organization) }

      let(:synced_columns) { %w[traversal_ids organization_id] }

      where(:column, :stale_value) do
        :traversal_ids   | []
        :organization_id | lazy { other_organization.id }
        :organization_id | nil
      end

      with_them do
        before do
          redis_shared_state_cleanup!
          Ci::NamespaceMirror.by_namespace_id(namespace.id).update_all(column => stale_value)

          allow_next_instance_of(Database::ConsistencyCheckService) do |instance|
            allow(instance).to receive(:random_start_id).and_return(namespace.id)
          end
        end

        it 'reports the mismatch and schedules a resync' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(
            :results,
            a_hash_including(
              mismatches: 1,
              mismatches_details: [{
                id: namespace.id,
                source_table: namespace.attributes.values_at(*synced_columns),
                target_table: namespace.attributes.merge(column.to_s => stale_value).values_at(*synced_columns)
              }]
            )
          )

          expect { worker.perform }.to change { Namespaces::SyncEvent.where(namespace_id: namespace.id).count }.by(1)
        end
      end
    end
  end
end
