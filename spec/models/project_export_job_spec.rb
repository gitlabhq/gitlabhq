# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectExportJob, feature_category: :importers, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:relation_exports) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:jid) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'scopes' do
    let_it_be(:current_time) { Time.current }
    let_it_be(:eight_days_ago) { current_time - 8.days }
    let_it_be(:seven_days_ago) { current_time - 7.days }
    let_it_be(:five_days_ago) { current_time - 5.days }

    let_it_be(:recent_export_job) { create(:project_export_job, updated_at: five_days_ago) }
    let_it_be(:week_old_export_job) { create(:project_export_job, updated_at: seven_days_ago) }
    let_it_be(:prunable_export_job_1) { create(:project_export_job, updated_at: eight_days_ago) }
    let_it_be(:prunable_export_job_2) { create(:project_export_job, updated_at: eight_days_ago) }

    around do |example|
      travel_to(current_time) { example.run }
    end

    describe '.prunable' do
      it 'only includes records with updated_at older than 7 days ago' do
        expect(described_class.prunable).to match_array([prunable_export_job_1, prunable_export_job_2])
      end
    end

    describe '.order_by_updated_at' do
      it 'sorts by updated_at' do
        expect(described_class.order_by_updated_at).to eq(
          [
            prunable_export_job_1,
            prunable_export_job_2,
            week_old_export_job,
            recent_export_job
          ]
        )
      end

      it 'uses id as a tiebreaker' do
        export_jobs_with_same_updated_at = described_class.where(updated_at: eight_days_ago).order_by_updated_at

        expect(export_jobs_with_same_updated_at[0].id).to be < export_jobs_with_same_updated_at[1].id
      end
    end
  end
end
