# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ClickHouse::FinishedPipelinesSyncCronWorker, :click_house, :freeze_time, feature_category: :fleet_visibility do
  let(:worker) { described_class.new }
  let(:args) { [3] }

  subject(:perform) { worker.perform(*args) }

  it 'invokes 3 workers' do
    expect(Ci::ClickHouse::FinishedPipelinesSyncWorker).to receive(:perform_async).with(0, 3).once
    expect(Ci::ClickHouse::FinishedPipelinesSyncWorker).to receive(:perform_async).with(1, 3).once
    expect(Ci::ClickHouse::FinishedPipelinesSyncWorker).to receive(:perform_async).with(2, 3).once

    perform
  end

  context 'when arguments are not specified' do
    let(:args) { [] }

    it 'invokes 1 worker with specified arguments' do
      expect(Ci::ClickHouse::FinishedPipelinesSyncWorker).to receive(:perform_async).with(0, 1)

      perform
    end
  end

  context 'when clickhouse database is not available' do
    before do
      allow(Gitlab::ClickHouse).to receive(:configured?).and_return(false)
    end

    it 'does nothing' do
      expect(Ci::ClickHouse::FinishedPipelinesSyncWorker).not_to receive(:perform_async)

      perform
    end
  end
end
