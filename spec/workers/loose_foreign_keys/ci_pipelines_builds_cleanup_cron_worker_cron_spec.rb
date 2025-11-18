# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::CiPipelinesBuildsCleanupCronWorker, feature_category: :database do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'passes the correct worker_class to ProcessDeletedRecordsService' do
      expect(LooseForeignKeys::ProcessDeletedRecordsService).to receive(:new).with(
        hash_including(worker_class: described_class)
      ).and_call_original

      allow_next_instance_of(LooseForeignKeys::ProcessDeletedRecordsService) do |service|
        allow(service).to receive(:execute).and_return({ delete_count: 0, update_count: 0 })
      end

      worker.perform
    end
  end

  describe 'worker configuration' do
    it 'has correct Sidekiq configuration' do
      expect(described_class.ancestors).to include(ApplicationWorker)
      expect(described_class.ancestors).to include(Gitlab::ExclusiveLeaseHelpers)
      expect(described_class.get_sidekiq_options['retry']).to be_falsey
    end
  end

  describe 'cleanup functionality' do
    let_it_be(:project) { create(:project) }
    let_it_be(:ci_pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:ci_build) { create(:ci_build, pipeline: ci_pipeline) }

    it 'processes LFK records' do
      # Delete the CI Pipeline and the CI Build
      ci_pipeline.destroy!

      # Verify the LFK record was created by the trigger and that running the worker processes it
      expect do
        worker.perform
      end.to change {
        Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
          LooseForeignKeys::DeletedRecord.where(
            fully_qualified_table_name: ['public.p_ci_pipelines', 'public.p_ci_builds'],
            status: 1
          ).count
        end
      }.by(-2)
    end
  end

  describe 'when turbo mode is turned off' do
    before do
      stub_feature_flags(loose_foreign_keys_turbo_mode_ci: false)
    end

    it 'does not use TurboModificationTracker' do
      allow_next_instance_of(LooseForeignKeys::TurboModificationTracker) do |instance|
        expect(instance).not_to receive(:over_limit?)
      end

      worker.perform
    end
  end
end
