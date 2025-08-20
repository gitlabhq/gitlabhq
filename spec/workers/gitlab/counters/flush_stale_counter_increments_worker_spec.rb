# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Counters::FlushStaleCounterIncrementsWorker, :saas, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let(:worker) { described_class.new }
  let(:redis_key) { "flush_stale_counters:last_id:#{ProjectDailyStatistic.name}" }
  let(:batch_limit) { described_class::BATCH_LIMIT }
  let_it_be(:project) { create :project }

  let!(:project_daily_statistic) do
    create(:project_daily_statistic, date: Date.new(2025, 2, 1), fetch_count: 5, project: project)
  end

  let!(:project_daily_statistic_two) do
    create(:project_daily_statistic, date: Date.new(2025, 2, 2), fetch_count: 0, project: project)
  end

  let!(:project_daily_statistic_three) do
    create(:project_daily_statistic, date: Date.new(2025, 2, 3), fetch_count: 10, project: project)
  end

  let(:keys) do
    [
      project_daily_statistic.counter('fetch_count').key,
      project_daily_statistic_two.counter('fetch_count').key,
      project_daily_statistic_three.counter('fetch_count').key
    ]
  end

  before do
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(keys[0], 5)
      redis.set(keys[2], 10)
    end
  end

  describe '#remaining_work_count' do
    context 'when there is work' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(redis_key, project_daily_statistic.id)
        end
        stub_const("#{described_class}::ID_RANGES", { ProjectDailyStatistic => {
          end_id: project_daily_statistic_three.id
        } })
      end

      it 'has work to do' do
        expect(worker.remaining_work_count).to eq(2)
      end
    end

    context 'when there is no more work' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(redis_key, project_daily_statistic_three.id)
        end
        stub_const("#{described_class}::ID_RANGES", { ProjectDailyStatistic => {
          end_id: project_daily_statistic_three.id
        } })
      end

      it 'has no more work to do' do
        expect(worker.remaining_work_count).to eq(0)
      end
    end
  end

  describe '#max_running_jobs' do
    it 'has only one concurrently running job' do
      expect(worker.max_running_jobs).to eq(1)
    end
  end

  describe '#perform_work' do
    context 'when there is remaining work' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(redis_key, project_daily_statistic.id)
          stub_const("#{described_class}::ID_RANGES", { ProjectDailyStatistic => {
            end_id: project_daily_statistic_three.id
          } })
          stub_const("#{described_class}::BATCH_LIMIT", 1)
        end
      end

      it "flushes stale counters and updates the redis start id" do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.get(redis_key).to_i).to eq(project_daily_statistic.id)
        end

        # We'll expect no change here since the worker will be removed.
        expect_initial_counts
        worker.perform_work
        expect_initial_counts

        Gitlab::Redis::SharedState.with do |redis|
          # We'll expect no change since the worker will be removed.
          expect(redis.get(redis_key).to_i).to eq(project_daily_statistic.id)
        end
      end

      def expect_initial_counts
        expect(project_daily_statistic.fetch_count).to eq(5)
        expect(project_daily_statistic_two.fetch_count).to eq(0)
        expect(project_daily_statistic_three.fetch_count).to eq(10)
      end
    end
  end
end
