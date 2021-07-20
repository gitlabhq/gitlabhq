# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ArchiveTraceWorker do
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
