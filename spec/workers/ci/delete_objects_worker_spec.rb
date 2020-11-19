# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteObjectsWorker do
  let(:worker) { described_class.new }

  it { expect(described_class.idempotent?).to be_truthy }

  describe '#perform' do
    it 'executes a service' do
      allow(worker).to receive(:max_running_jobs).and_return(25)

      expect_next_instance_of(Ci::DeleteObjectsService) do |instance|
        expect(instance).to receive(:execute)
        expect(instance).to receive(:remaining_batches_count)
          .with(max_batch_count: 25)
          .once
          .and_call_original
      end

      worker.perform
    end
  end

  describe '#max_running_jobs' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_feature_flags(
        ci_delete_objects_medium_concurrency: medium,
        ci_delete_objects_high_concurrency: high
      )
    end

    subject(:max_running_jobs) { worker.max_running_jobs }

    where(:medium, :high, :expected) do
      false | false | 2
      true  | false | 20
      true  | true  | 20
      false | true  | 50
    end

    with_them do
      it 'sets up concurrency depending on the feature flag' do
        expect(max_running_jobs).to eq(expected)
      end
    end
  end
end
