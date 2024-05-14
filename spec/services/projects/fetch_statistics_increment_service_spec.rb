# frozen_string_literal: true

require 'spec_helper'

module Projects
  RSpec.describe FetchStatisticsIncrementService, feature_category: :groups_and_projects do
    let(:project) { create(:project) }
    let!(:yesterday_stat) { create(:project_daily_statistic, fetch_count: 3, project: project, date: 1.day.ago) }

    describe '#execute' do
      shared_examples 'an increment service' do
        context "when no record for today is present" do
          it 'creates a new record for today' do
            expect { subject }.to change { ProjectDailyStatistic.count }.by(1)
          end

          it 'increment the new record' do
            subject
            new_record = ProjectDailyStatistic.last
            expect(new_record.fetch_count).to eq(1)
            expect(new_record.project).to eq(project)
            expect(new_record.date).to eq(Date.today)
          end
        end

        context "when today record is present" do
          let!(:project_daily_stat) { create(:project_daily_statistic, fetch_count: 5, project: project, date: Date.today) }

          it 'increment the existing record' do
            expect { subject }.to change { project_daily_stat.reload.fetch_count }.to(6)
          end

          it "doesn't increment yesterday record" do
            expect { subject }.not_to change { yesterday_stat.reload.fetch_count }
          end
        end
      end

      context "when project_daily_statistic_counter_attribute_fetch features flag is disabled" do
        subject { described_class.new(project).execute }

        before do
          stub_feature_flags(project_daily_statistic_counter_attribute_fetch: false)
        end

        it_behaves_like "an increment service"
      end

      context "when project_daily_statistic_counter_attribute_fetch features flag is enabled" do
        subject do
          described_class.new(project).execute
          # Update with the feature flag is async (counterAtrribute)
          # forcing an update to the DB for the tests
          current = ProjectDailyStatistic.find_or_create_project_daily_statistic(project.id, Date.today)
          current.counter(:fetch_count).commit_increment!
        end

        it_behaves_like "an increment service"
      end
    end
  end
end
