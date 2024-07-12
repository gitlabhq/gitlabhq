# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ClickHouse::FinishedPipelinesSyncWorker, :click_house, :freeze_time, feature_category: :fleet_visibility do
  let(:worker) { described_class.new }

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline1) do
    create(:ci_pipeline, :success, project: project, ref: 'master', source: :push,
      committed_at: 2.hours.before(1.month.ago), started_at: 1.hour.before(1.month.ago), finished_at: 1.month.ago,
      duration: 60 * 60)
  end

  let_it_be(:pipeline2) do
    create(:ci_pipeline, :pending, project: project, ref: 'main', source: :schedule)
  end

  subject(:perform) { worker.perform }

  before do
    create_sync_events pipeline1
  end

  specify do
    expect(worker.class.click_house_worker_attrs).to match(
      a_hash_including(migration_lock_ttl: ClickHouse::MigrationSupport::ExclusiveLock::DEFAULT_CLICKHOUSE_WORKER_TTL)
    )
  end

  include_examples 'an idempotent worker' do
    it 'calls CiFinishedPipelinesSyncService and returns its response payload' do
      expect(worker).to receive(:log_extra_metadata_on_done)
        .with(:result, {
          reached_end_of_table: true, records_inserted: 1,
          worker_index: 0, total_workers: 1
        })

      params = { worker_index: 0, total_workers: 1 }
      expect_next_instance_of(::Ci::ClickHouse::DataIngestion::FinishedPipelinesSyncService, params) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      expect(ClickHouse::Client).to receive(:insert_csv).once.and_call_original

      expect { perform }.to change { ci_finished_pipelines_row_count }.by(::Ci::Pipeline.finished.count)
    end

    context 'when an error is reported from service' do
      before do
        allow(Gitlab::ClickHouse).to receive(:configured?).and_return(false)
      end

      it 'skips execution' do
        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:result, { message: 'Disabled: ClickHouse database is not configured.', reason: :db_not_configured })

        perform
      end
    end
  end

  context 'when exclusive lease error happens' do
    context 'when the exclusive lease is already locked for the worker' do
      it 'does nothing' do
        expect_next_instance_of(::Ci::ClickHouse::DataIngestion::FinishedPipelinesSyncService) do |service|
          expect(service).to receive(:in_lock).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
        end

        expect { perform }.not_to change { ci_finished_pipelines_row_count }

        expect(perform).to eq({
          message: 'Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError',
          reason: :skipped
        })
      end
    end
  end

  context 'with 2 workers' do
    using RSpec::Parameterized::TableSyntax

    subject(:perform) { worker.perform(worker_index, 2) }

    where(:worker_index) { [0, 1] }

    with_them do
      let(:params) { { worker_index: worker_index, total_workers: 2 } }

      it 'processes record if it falls on specified partition' do
        # select the records that fall in the specified partition
        partition_count = ::Ci::ClickHouse::DataIngestion::FinishedPipelinesSyncService::PIPELINE_ID_PARTITIONS
        modulus_arel = Arel.sql("(pipeline_id % #{partition_count})")
        lower_bound = (worker_index * partition_count / params[:total_workers]).to_i
        upper_bound = ((worker_index + 1) * partition_count / params[:total_workers]).to_i
        pipeline_ids =
          Ci::FinishedPipelineChSyncEvent
            .where(modulus_arel.gteq(lower_bound))
            .where(modulus_arel.lt(upper_bound))
            .map(&:pipeline_id)

        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:result, { reached_end_of_table: true, records_inserted: pipeline_ids.count }.merge(params))

        expect_next_instance_of(::Ci::ClickHouse::DataIngestion::FinishedPipelinesSyncService, params) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        if pipeline_ids.any?
          expect(ClickHouse::Client).to receive(:insert_csv).once.and_call_original
        else
          expect(ClickHouse::Client).not_to receive(:insert_csv)
        end

        perform
      end
    end
  end

  def create_sync_events(*pipelines)
    pipelines.each do |pipeline|
      Ci::FinishedPipelineChSyncEvent.new(
        pipeline_id: pipeline.id, pipeline_finished_at: pipeline.finished_at,
        project_namespace_id: pipeline.project.project_namespace_id
      ).save!
    end
  end

  def ci_finished_pipelines_row_count
    ClickHouse::Client.select('SELECT COUNT(*) AS count FROM ci_finished_pipelines FINAL', :main).first['count']
  end
end
