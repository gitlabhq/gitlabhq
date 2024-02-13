# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProcessOutdatedNamespaceDescendantsCronWorker, feature_category: :database do
  let(:worker) { described_class.new }

  subject(:run_job) { worker.perform }

  include_examples 'an idempotent worker' do
    it 'executes sucessfully' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { processed_namespaces: 0 })

      run_job
    end
  end

  context 'when there are records to be processed' do
    let_it_be_with_reload(:outdated1) { create(:namespace_descendants, :outdated) }
    let_it_be_with_reload(:outdated2) { create(:namespace_descendants, :outdated) }

    it 'invokes the service and increments the processed_namespaces' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { processed_namespaces: 2 })

      run_job

      outdated1.reload
      outdated2.reload

      expect(outdated1.outdated_at).to eq(nil)
      expect(outdated2.outdated_at).to eq(nil)
    end

    context 'when time limit is reached' do
      it 'stops the processing' do
        allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
          allow(runtime_limiter).to receive(:over_time?).and_return(true) # stop after the 1st record
        end

        expect(worker).to receive(:log_extra_metadata_on_done).with(:result, { processed_namespaces: 1 })

        run_job
      end
    end
  end
end
