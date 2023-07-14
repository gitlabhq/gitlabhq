# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCleanupRefWorker, :sidekiq_inline, feature_category: :continuous_integration do
  include ExclusiveLeaseHelpers

  let_it_be(:pipeline) { create(:ci_pipeline, :success) }

  let(:worker) { described_class.new }

  subject { worker.perform(pipeline.id) }

  it 'does remove persistent ref' do
    expect_next_instance_of(Ci::PersistentRef) do |persistent_ref|
      expect(persistent_ref).to receive(:delete).once
    end

    subject
  end

  context 'when pipeline is still running' do
    let_it_be(:pipeline) { create(:ci_pipeline, :running) }

    it 'does not remove persistent ref' do
      expect_next_instance_of(Ci::PersistentRef) do |persistent_ref|
        expect(persistent_ref).not_to receive(:delete)
      end

      subject
    end
  end

  context 'when pipeline status changes while being locked' do
    let_it_be(:pipeline) { create(:ci_pipeline, :success) }

    it 'does not remove persistent ref' do
      expect_next_instance_of(Ci::PersistentRef) do |persistent_ref|
        expect(persistent_ref).not_to receive(:delete_refs)
      end

      expect(worker).to receive(:in_lock).and_wrap_original do |method, *args, **kwargs, &block|
        pipeline.run!

        method.call(*args, **kwargs, &block)
      end

      subject
    end
  end

  context 'when max retry attempts reach' do
    let(:lease_key) { "projects/#{pipeline.project_id}/serialized_remove_refs" }
    let!(:lease) { stub_exclusive_lease_taken(lease_key) }

    it 'does not raise error' do
      expect(lease).to receive(:try_obtain).exactly(described_class::LOCK_RETRY + 1).times
      expect { subject }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
    end
  end
end
