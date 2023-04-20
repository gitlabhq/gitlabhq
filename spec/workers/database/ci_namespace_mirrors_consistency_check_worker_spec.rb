# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::CiNamespaceMirrorsConsistencyCheckWorker, feature_category: :cell do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes the consistency check on namespaces' do
      expect(Database::ConsistencyCheckService).to receive(:new).and_call_original
      expected_result = { batches: 0, matches: 0, mismatches: 0, mismatches_details: [] }
      expect(worker).to receive(:log_extra_metadata_on_done).with(:results, expected_result)
      worker.perform
    end

    context 'logs should contain the detailed mismatches' do
      let(:first_namespace) { Namespace.all.order(:id).limit(1).first }
      let(:missing_namespace) { Namespace.all.order(:id).limit(2).last }

      before do
        redis_shared_state_cleanup!
        create_list(:namespace, 10) # This will also create Ci::NameSpaceMirror objects
        missing_namespace.delete

        allow_next_instance_of(Database::ConsistencyCheckService) do |instance|
          allow(instance).to receive(:random_start_id).and_return(Namespace.first.id)
        end
      end

      it 'reports the differences to the logs' do
        expected_result = {
          batches: 1,
          matches: 9,
          mismatches: 1,
          mismatches_details: [{
            id: missing_namespace.id,
            source_table: nil,
            target_table: [missing_namespace.traversal_ids]
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
  end
end
