# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProcessOutdatedNamespaceDescendantsCronWorker, feature_category: :database do
  let(:worker) { described_class.new }

  subject(:run_job) { worker.perform }

  include_examples 'an idempotent worker' do
    it 'executes successfully' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
        { processed_namespaces: 0, skipped_namespaces: 0 })

      run_job
    end
  end

  context 'when there are records to be processed' do
    let_it_be_with_reload(:outdated1) { create(:namespace_descendants, :outdated) }
    let_it_be_with_reload(:outdated2) { create(:namespace_descendants, :outdated) }
    let_it_be_with_reload(:outdated3) { create(:namespace_descendants, :outdated) }

    it 'invokes the service and increments the processed_namespaces' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
        { processed_namespaces: 3, skipped_namespaces: 0 })

      run_job

      outdated1.reload
      outdated2.reload
      outdated3.reload

      expect(outdated1.outdated_at).to eq(nil)
      expect(outdated2.outdated_at).to eq(nil)
      expect(outdated3.outdated_at).to eq(nil)
    end

    context 'when namespace was skipped due to locking' do
      it 'the processed_namespaces' do
        # rubocop: disable RSpec/AnyInstanceOf -- I need to provide fake implementation for the method call globally as testing DB-level record locking is not trivial in RSpec.
        allow_any_instance_of(Namespaces::UpdateDenormalizedDescendantsService).to receive(:execute) do |instance|
          namespace_id = instance.send(:namespace_id)
          # Emulate locked scenario for the 2nd record
          if namespace_id == outdated2.namespace_id
            nil
          else
            # Mark the record up to date like the service does.
            Namespaces::Descendants.where(namespace_id: namespace_id).update_all(outdated_at: nil)

            :processed
          end
        end
        # rubocop: enable RSpec/AnyInstanceOf

        expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
          { processed_namespaces: 2, skipped_namespaces: 1 })

        run_job

        outdated1.reload
        outdated2.reload
        outdated3.reload

        expect(outdated1.outdated_at).to eq(nil)
        expect(outdated2.outdated_at).not_to eq(nil)
        expect(outdated3.outdated_at).to eq(nil)
      end
    end

    context 'when time limit is reached' do
      it 'stops the processing' do
        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
          allow(runtime_limiter).to receive(:over_time?).and_return(true) # stop after the 1st record
        end

        expect(worker).to receive(:log_extra_metadata_on_done).with(:result,
          { processed_namespaces: 1, skipped_namespaces: 0 })

        run_job
      end
    end
  end
end
