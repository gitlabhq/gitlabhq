# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ClickHouse::FinishedPipelinesSyncCronWorker, :click_house, :freeze_time, feature_category: :fleet_visibility do
  let(:worker) { described_class.new }
  let(:args) { [2] }

  let(:medium_workers_ff) { false }
  let(:high_workers_ff) { false }

  subject(:perform) { worker.perform(*args) }

  before do
    stub_feature_flags(
      ci_finished_pipelines_sync_medium_workers: medium_workers_ff,
      ci_finished_pipelines_sync_high_workers: high_workers_ff
    )
  end

  it 'uses the args value' do
    args.first.times do |i|
      expect(Ci::ClickHouse::FinishedPipelinesSyncWorker).to receive(:perform_async).with(i, args.first).once
    end

    perform
  end

  context 'when arguments are not specified' do
    let(:args) { [] }

    it 'invokes 1 worker by default' do
      expect(Ci::ClickHouse::FinishedPipelinesSyncWorker).to receive(:perform_async).with(0, 1)

      perform
    end
  end

  context 'when ci_finished_pipelines_sync_medium_workers feature flag is enabled' do
    let(:medium_workers_ff) { true }

    it 'invokes MEDIUM_WORKERS workers regardless of args' do
      described_class::MEDIUM_WORKERS.times do |i|
        expect(Ci::ClickHouse::FinishedPipelinesSyncWorker)
          .to receive(:perform_async).with(i, described_class::MEDIUM_WORKERS).once
      end

      perform
    end
  end

  context 'when ci_finished_pipelines_sync_high_workers feature flag is enabled' do
    let(:high_workers_ff) { true }

    it 'invokes HIGH_WORKERS workers regardless of args' do
      described_class::HIGH_WORKERS.times do |i|
        expect(Ci::ClickHouse::FinishedPipelinesSyncWorker)
          .to receive(:perform_async).with(i, described_class::HIGH_WORKERS).once
      end

      perform
    end
  end

  context 'when both feature flags are enabled' do
    let(:medium_workers_ff) { true }
    let(:high_workers_ff) { true }

    it 'prefers high workers over medium' do
      described_class::HIGH_WORKERS.times do |i|
        expect(Ci::ClickHouse::FinishedPipelinesSyncWorker)
          .to receive(:perform_async).with(i, described_class::HIGH_WORKERS).once
      end

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
