# frozen_string_literal: true

require 'spec_helper'

module Projects
  RSpec.describe FetchStatisticsIncrementService, feature_category: :groups_and_projects do
    let_it_be(:project) { create(:project) }
    let_it_be(:yesterday_stat) { create(:project_daily_statistic, fetch_count: 3, project: project, date: 1.day.ago) }

    describe '#execute', :sidekiq_inline do
      context "when no record for today is present" do
        it 'creates a new record for today and increments fetch_count' do
          expect { described_class.new(project).execute }.to change { ProjectDailyStatistic.count }.by(1)

          new_record = ProjectDailyStatistic.last
          expect(new_record.fetch_count).to eq(1)
          expect(new_record.project).to eq(project)
          expect(new_record.date).to eq(Date.today)
        end
      end

      context "when today's record is present" do
        let_it_be(:project_daily_stat) { create(:project_daily_statistic, fetch_count: 5, project: project, date: Date.today) }

        it 'increments the existing record' do
          expect { described_class.new(project).execute }.to change { project_daily_stat.reload.fetch_count }.by(1)
        end

        it "doesn't increment yesterday's record" do
          expect { described_class.new(project).execute }.not_to change { yesterday_stat.reload.fetch_count }
        end
      end
    end
  end
end
