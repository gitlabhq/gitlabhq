# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ClickHouse::DataIngestion::FinishedPipelinesSyncService, '#execute',
  :click_house, :freeze_time, feature_category: :fleet_visibility do
  subject(:execute) { service.execute }

  let(:service) { described_class.new }

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:pipeline1) do
    create(:ci_pipeline, :success, project: project1, ref: 'master', source: :push,
      committed_at: 2.hours.before(1.month.ago), started_at: 1.hour.before(1.month.ago), finished_at: 1.month.ago,
      duration: 1.hour.in_seconds)
  end

  let_it_be(:pipeline2) do
    create(:ci_pipeline, :canceled, project: project2, ref: 'main', finished_at: 1.week.ago, source: :schedule)
  end

  let_it_be(:pipeline3) do
    create(:ci_pipeline, :failed, project: project2, ref: 'feature/a', source: :api,
      committed_at: nil, started_at: 1.minute.before(1.day.ago), finished_at: 1.day.ago,
      duration: -2) # we do actually have negative durations in the database
  end

  let_it_be(:pipeline4) do
    create(:ci_pipeline, :failed, project: project2, ref: 'UAT', source: :api,
      committed_at: nil, started_at: nil, finished_at: 1.day.ago,
      duration: nil) # we do actually have null durations in the database
  end

  let_it_be(:pipeline5) { create(:ci_pipeline, :pending, project: project1, ref: 'feature/b') }

  let_it_be(:pipeline_with_name) { create(:ci_pipeline, :success, name: 'name', finished_at: 1.week.ago) }

  before_all do
    create_sync_events(*Ci::Pipeline.finished.order(id: :desc))
  end

  context 'when all pipelines fit in a single batch' do
    it 'processes the pipelines' do
      expect(ClickHouse::Client).to receive(:insert_csv).once.and_call_original

      expect { execute }.to change { ci_finished_pipelines_row_count }.by(5)
      expect(execute).to have_attributes({
        payload: {
          reached_end_of_table: true,
          records_inserted: 5,
          worker_index: 0, total_workers: 1
        }
      })

      records = ci_finished_pipelines
      expect(records.count).to eq 5
      expect(records).to contain_exactly_pipelines(pipeline1, pipeline2, pipeline3, pipeline4, pipeline_with_name)
    end

    it 'processes only pipelines from Ci::FinishedPipelineChSyncEvent' do
      pipeline = create(:ci_pipeline, :failed, finished_at: 1.minute.ago)

      expect { execute }.to change { ci_finished_pipelines_row_count }.by(5)
      expect(execute).to have_attributes({
        payload: a_hash_including(reached_end_of_table: true, records_inserted: 5)
      })

      create_sync_events(pipeline)
      expect { service.execute }.to change { ci_finished_pipelines_row_count }.by(1)
    end

    context 'when a finished pipeline has been deleted' do
      it 'marks the sync event as processed' do
        sync_event = Ci::FinishedPipelineChSyncEvent
          .new(pipeline_id: non_existing_record_id, pipeline_finished_at: Time.current, project_namespace_id: 1)
          .tap(&:save!)

        expect { execute }
          .to change { ci_finished_pipelines_row_count }.by(5)
          .and change { sync_event.reload.processed }.to(true)
      end
    end

    context 'when one of the finished pipelines has invalid attributes' do
      let_it_be(:group2) { create(:group) }
      let_it_be(:project3) { create(:project, group: group2) }

      # Create a pipeline with a project that has no namespace traversal path
      # This will cause the pipeline to be considered invalid and be skipped
      let!(:pipeline_with_invalid_mirror) do
        create(:ci_pipeline, :failed, project: project3, finished_at: 1.minute.ago)
      end

      before_all do
        group2.ci_namespace_mirror.destroy!
      end

      before do
        create_sync_events(pipeline_with_invalid_mirror)
      end

      specify { expect(group2.reload.ci_namespace_mirror).to be_nil }

      it 'skips the invalid pipeline and does not mark the sync event as processed' do
        expect(Gitlab::AppJsonLogger).to receive(:warn).with(
          message: 'A problematic pipeline sync event has been encountered',
          reason: 'Missing namespace traversal path',
          pipeline_id: pipeline_with_invalid_mirror.id
        )

        expect { execute }
          .to change { ci_finished_pipelines_row_count }.by(5)
          .and change { Ci::FinishedPipelineChSyncEvent.pending.count }.to(1)

        # Verify the invalid pipeline was not inserted
        records = ci_finished_pipelines
        expect(records.count).to eq 5
        expect(records.pluck(:id)).not_to include(pipeline_with_invalid_mirror.id)
      end
    end
  end

  context 'when multiple batches are required' do
    before do
      stub_const("#{described_class}::PIPELINES_BATCH_SIZE", 2)
    end

    it 'processes the pipelines' do
      expect(ClickHouse::Client).to receive(:insert_csv).once.and_call_original

      expect { execute }.to change { ci_finished_pipelines_row_count }.by(5)
      expect(execute).to have_attributes({
        payload: a_hash_including(reached_end_of_table: true, records_inserted: 5)
      })
    end
  end

  context 'when multiple CSV uploads are required' do
    before do
      stub_const("#{described_class}::PIPELINES_BATCH_SIZE", 1)
      stub_const("#{described_class}::PIPELINES_BATCH_COUNT", 3)
    end

    it 'processes the pipelines' do
      expect_next_instance_of(Gitlab::Pagination::Keyset::Iterator) do |iterator|
        expect(iterator).to receive(:each_batch).once.with(of: described_class::PIPELINES_BATCH_SIZE).and_call_original
      end

      expect(ClickHouse::Client).to receive(:insert_csv).twice.and_call_original

      expect { execute }.to change { ci_finished_pipelines_row_count }.by(5)
      expect(execute).to have_attributes({
        payload: a_hash_including(reached_end_of_table: true, records_inserted: 5)
      })
    end

    context 'with time limit being reached' do
      it 'processes the pipelines of the first batch' do
        over_time = false

        expect_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |limiter|
          expect(limiter).to receive(:over_time?).at_least(1) { over_time }
        end

        expect(service).to receive(:yield_pipelines).and_wrap_original do |original, *args|
          over_time = true
          original.call(*args)
        end

        expect { execute }.to change { ci_finished_pipelines_row_count }.by(described_class::PIPELINES_BATCH_SIZE)
        expect(execute).to have_attributes({
          payload: a_hash_including(
            reached_end_of_table: false, records_inserted: described_class::PIPELINES_BATCH_SIZE
          )
        })
      end
    end

    context 'when batches fail to be written to ClickHouse' do
      it 'does not mark any records as processed' do
        expect(ClickHouse::Client).to receive(:insert_csv) { raise ClickHouse::Client::DatabaseError }

        expect { execute }.to raise_error(ClickHouse::Client::DatabaseError)
          .and not_change { Ci::FinishedPipelineChSyncEvent.pending.count }
      end
    end
  end

  context 'with multiple calls to service' do
    it 'processes the pipelines' do
      expect_next_instances_of(Gitlab::Pagination::Keyset::Iterator, 2) do |iterator|
        expect(iterator).to receive(:each_batch).once.with(of: described_class::PIPELINES_BATCH_SIZE).and_call_original
      end

      expect { execute }.to change { ci_finished_pipelines_row_count }.by(5)
      expect(execute).to have_attributes({
        payload: a_hash_including(reached_end_of_table: true, records_inserted: 5)
      })

      pipeline6 = create(:ci_pipeline, :failed, finished_at: 1.minute.ago)
      create_sync_events(pipeline6)

      expect { service.execute }.to change { ci_finished_pipelines_row_count }.by(1)
      records = ci_finished_pipelines
      expect(records.count).to eq 6
      expect(records).to contain_exactly_pipelines(
        pipeline1, pipeline2, pipeline3, pipeline4, pipeline_with_name, pipeline6
      )
    end

    context 'with same updated_at value' do
      it 'processes the pipelines' do
        expect { service.execute }.to change { ci_finished_pipelines_row_count }.by(5)

        pipeline6 = create(:ci_pipeline, :failed, finished_at: 1.second.ago, updated_at: 1.second.ago)
        pipeline7 = create(:ci_pipeline, :failed, finished_at: 1.second.ago, updated_at: 1.second.ago)
        create_sync_events(pipeline6, pipeline7)

        expect { execute }.to change { ci_finished_pipelines_row_count }.by(2)

        records = ci_finished_pipelines
        expect(records.count).to eq 7
        expect(records).to contain_exactly_pipelines(
          pipeline1, pipeline2, pipeline3, pipeline4, pipeline_with_name,
          pipeline6, pipeline7
        )
      end
    end

    context 'with older finished_at value' do
      it 'does not process the pipeline' do
        expect { service.execute }.to change { ci_finished_pipelines_row_count }.by(5)

        create(:ci_pipeline, :failed, finished_at: 2.days.ago)

        expect { service.execute }.not_to change { ci_finished_pipelines_row_count }
      end
    end
  end

  context 'when no ClickHouse databases are configured' do
    before do
      allow(Gitlab::ClickHouse).to receive(:configured?).and_return(false)
    end

    it 'skips execution' do
      is_expected.to have_attributes({
        status: :error,
        message: 'Disabled: ClickHouse database is not configured.',
        reason: :db_not_configured,
        payload: { worker_index: 0, total_workers: 1 }
      })
    end
  end

  context 'when exclusive lease error happens' do
    context 'when the exclusive lease is already locked for the worker' do
      let(:service) { described_class.new(worker_index: 2, total_workers: 3) }

      before do
        lock_name = "#{described_class.name.underscore}/worker/2"
        allow(service).to receive(:in_lock).with(lock_name, retries: 0, ttl: 360)
          .and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end

      it 'does nothing' do
        expect { execute }.not_to change { ci_finished_pipelines_row_count }

        expect(execute).to have_attributes({
          status: :error, reason: :skipped, payload: { worker_index: 2, total_workers: 3 }
        })
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

  def ci_finished_pipelines
    ClickHouse::Client
      .select('SELECT *, date FROM ci_finished_pipelines', :main)
      .map(&:symbolize_keys)
  end

  def expected_pipeline_attributes(pipeline)
    project = pipeline.project
    project.reload if project.project_namespace.traversal_ids.empty? # reload required to calculate traversal path

    {
      id: pipeline.id,
      path: project.project_namespace.traversal_path,
      committed_at: a_value_within(0.001.seconds).of(pipeline.committed_at || Time.at(0).utc),
      created_at: a_value_within(0.001.seconds).of(pipeline.created_at || Time.at(0).utc),
      started_at: a_value_within(0.001.seconds).of(pipeline.started_at || Time.at(0).utc),
      finished_at: a_value_within(0.001.seconds).of(pipeline.finished_at),
      duration: [0, pipeline.duration || 0].max,
      status: pipeline.status || '',
      source: pipeline.source || '',
      ref: pipeline.ref || '',
      date: pipeline.finished_at.beginning_of_month,
      name: pipeline.name || ''
    }
  end

  def contain_exactly_pipelines(*pipelines)
    expected_pipelines = pipelines.map do |pipeline|
      expected_pipeline_attributes(pipeline)
    end

    match_array(expected_pipelines)
  end
end
