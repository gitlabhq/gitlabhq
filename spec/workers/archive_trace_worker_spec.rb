# frozen_string_literal: true

require 'spec_helper'

describe ArchiveTraceWorker do
  describe '#perform' do
    subject { described_class.new.perform(job&.id) }

    context 'when job is found' do
      let(:job) { create(:ci_build, :trace_live) }

      it 'executes service' do
        expect_any_instance_of(Ci::ArchiveTraceService)
          .to receive(:execute).with(job, anything)

        subject
      end
    end

    context 'when job is not found' do
      let(:job) { nil }

      it 'does not execute service' do
        expect_any_instance_of(Ci::ArchiveTraceService)
          .not_to receive(:execute)

        subject
      end
    end
  end
end
