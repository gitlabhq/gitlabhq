# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Counters::FlushStaleCounterIncrements, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let(:date) { 1.month.ago }
  let(:collection) { ProjectDailyStatistic.where(date: date..) }
  let(:service) { described_class.new(collection) }

  let_it_be(:project) { create :project }

  let!(:project_daily_statistic) do
    create(:project_daily_statistic, date: Time.zone.today - 2.days, fetch_count: 5, project: project)
  end

  let!(:project_daily_statistic_two) do
    create(:project_daily_statistic, date: Time.zone.today - 1.day, fetch_count: 0, project: project)
  end

  let!(:project_daily_statistic_three) do
    create(:project_daily_statistic, date: Time.zone.today, fetch_count: 10, project: project)
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

  def expect_initial_counts
    expect(project_daily_statistic.fetch_count).to eq(5)
    expect(project_daily_statistic_two.fetch_count).to eq(0)
    expect(project_daily_statistic_three.fetch_count).to eq(10)
  end

  def expect_flushed_counts
    expect(project_daily_statistic.reload.fetch_count).to eq(10)
    expect(project_daily_statistic_two.reload.fetch_count).to eq(0)
    expect(project_daily_statistic_three.reload.fetch_count).to eq(20)
  end

  shared_examples 'flushes counters correctly' do
    it 'flushes and calls commit_increment!' do
      expect_initial_counts

      Gitlab::Redis::SharedState.with do |redis|
        if Gitlab::Redis::ClusterUtil.cluster?(redis)
          expect(Gitlab::Redis::ClusterUtil).to receive(:batch_get).with(keys, redis).and_return(["5", nil, 10])
        else
          expect(redis).to receive(:mget).and_return(["5", nil, 10])
        end
      end

      service.execute

      expect_flushed_counts
    end
  end

  describe '#execute' do
    context 'when Redis is in cluster mode' do
      before do
        allow(Gitlab::Redis::ClusterUtil).to receive(:cluster?).and_return(true)
      end

      it_behaves_like 'flushes counters correctly'
    end

    context 'when Redis is not in cluster mode' do
      before do
        allow(Gitlab::Redis::ClusterUtil).to receive(:cluster?).and_return(false)
      end

      it_behaves_like 'flushes counters correctly'
    end
  end
end
