# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildHooksWorker, feature_category: :continuous_integration do
  describe '#perform' do
    context 'when build exists' do
      let!(:build) { create(:ci_build) }

      it 'calls build hooks' do
        expect_any_instance_of(Ci::Build)
          .to receive(:execute_hooks)

        described_class.new.perform(build.id)
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end

  describe '.perform_async', :sidekiq_inline do
    it 'sends a message to the application logger, before performing' do
      build = create(:ci_build)

      expect(Gitlab::AppLogger).to receive(:info).with(
        message: include('Enqueuing hooks for Build'),
        class: described_class.name,
        build_id: build.id,
        pipeline_id: build.pipeline_id,
        project_id: build.project_id,
        build_status: build.status
      )

      expect_any_instance_of(Ci::Build).to receive(:execute_hooks)

      described_class.perform_async(build)
    end
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed
end
