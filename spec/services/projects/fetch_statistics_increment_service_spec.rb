# frozen_string_literal: true

require 'spec_helper'

module Projects
  RSpec.describe FetchStatisticsIncrementService do
    let(:project) { create(:project) }

    describe '#execute' do
      subject { described_class.new(project).execute }

      it 'creates a new record for today with count == 1' do
        expect { subject }.to change { ProjectDailyStatistic.count }.by(1)
        created_stat = ProjectDailyStatistic.last

        expect(created_stat.fetch_count).to eq(1)
        expect(created_stat.project).to eq(project)
        expect(created_stat.date).to eq(Date.today)
      end

      it "doesn't increment previous days statistics" do
        yesterday_stat = create(:project_daily_statistic, fetch_count: 5, project: project, date: 1.day.ago)

        expect { subject }.not_to change { yesterday_stat.reload.fetch_count }
      end

      context 'when the record already exists for today' do
        let!(:project_daily_stat) { create(:project_daily_statistic, fetch_count: 5, project: project, date: Date.today) }

        it 'increments the today record count by 1' do
          expect { subject }.to change { project_daily_stat.reload.fetch_count }.to(6)
        end
      end
    end
  end
end
