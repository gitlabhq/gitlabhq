# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ArchiveTraceWorker, feature_category: :continuous_integration do
  describe '#perform' do
    subject { described_class.new.perform(job&.id) }

    context 'when job is found' do
      let(:job) { create(:ci_build, :trace_live) }

      it 'executes service' do
        allow_next_instance_of(Ci::ArchiveTraceService) do |instance|
          allow(instance).to receive(:execute).with(job, anything)
        end

        subject
      end

      it 'has preloaded the arguments for archiving' do
        allow_next_instance_of(Ci::ArchiveTraceService) do |instance|
          allow(instance).to receive(:execute) do |job|
            expect(job.association(:project)).to be_loaded
            expect(job.association(:pending_state)).to be_loaded
          end
        end

        subject
      end
    end

    context 'when job is not found' do
      let(:job) { nil }

      it 'does not execute service' do
        allow_next_instance_of(Ci::ArchiveTraceService) do |instance|
          allow(instance).not_to receive(:execute)
        end

        subject
      end
    end
  end
end
