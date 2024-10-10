# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectDailyStatistic, feature_category: :groups_and_projects do
  let_it_be(:project) { create :project }

  it { is_expected.to belong_to(:project) }

  describe '#increment_fetch_count' do
    let(:daily_statistic) { create(:project_daily_statistic, project: project, date: Date.current) }

    subject(:increment!) { daily_statistic.increment_fetch_count(1) }

    it 'stores the increment temporarily in Redis', :clean_gitlab_redis_shared_state do
      increment!
      Gitlab::Redis::SharedState.with do |redis|
        key = daily_statistic.counter(:fetch_count).key
        value = redis.get(key)
        expect(value.to_i).to eq(1)
      end
    end

    it 'schedules a worker to update the fetch count', :sidekiq_inline do
      expect(FlushCounterIncrementsWorker)
        .to receive(:perform_in)
        .with(Gitlab::Counters::BufferedCounter::WORKER_DELAY, described_class.name, daily_statistic.id, 'fetch_count')
        .and_call_original

      expect { increment! }
        .to change { daily_statistic.reload.fetch_count }.by(1)
    end
  end

  describe '#find_or_create_project_daily_statistic' do
    let(:date) { Date.today }

    subject(:find_or_create) { described_class.find_or_create_project_daily_statistic(project.id, date) }

    context 'when the record does not exist for today' do
      it 'creates a new record' do
        expect { find_or_create }.to change { described_class.count }.by(1)

        created_stat = described_class.last

        expect(created_stat.fetch_count).to eq(0)
        expect(created_stat.project).to eq(project)
        expect(created_stat.date).to eq(Date.today)
        expect(find_or_create).to eq(created_stat)
      end
    end

    context 'when the record already exists for today' do
      let!(:project_daily_stat) { create(:project_daily_statistic, fetch_count: 5, project: project, date: Date.today) }

      it 'does not create a record' do
        expect { find_or_create }.not_to change { described_class.count }

        expect(find_or_create).to eq(project_daily_stat)
      end

      context 'and has just been created' do
        # Mocks:
        # 1. First find_by, record not yet created
        # 2. Attempt to upsert, returns nil as a duplicate record has just been created concurrently
        # 3. The last find_by get the created record
        first_call_stubbed = true

        it 'is thread safe' do
          allow(described_class).to receive(:find_by) do
            if first_call_stubbed
              first_call_stubbed = false
              nil
            else
              project_daily_stat
            end
          end
          allow(described_class).to receive(:upsert).and_return(ActiveRecord::Result.new(['id'], []))
          expect { find_or_create }.not_to change { described_class.count }

          expect(find_or_create).to eq(project_daily_stat)
        end
      end
    end
  end
end
