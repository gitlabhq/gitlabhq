# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20191030152934_move_limits_from_plans.rb')

describe MoveLimitsFromPlans, :migration do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  let!(:early_adopter_plan) { plans.create(name: 'early_adopter', title: 'Early adopter', active_pipelines_limit: 10, pipeline_size_limit: 11, active_jobs_limit: 12) }
  let!(:gold_plan) { plans.create(name: 'gold', title: 'Gold', active_pipelines_limit: 20, pipeline_size_limit: 21, active_jobs_limit: 22) }
  let!(:silver_plan) { plans.create(name: 'silver', title: 'Silver', active_pipelines_limit: 30, pipeline_size_limit: 31, active_jobs_limit: 32) }
  let!(:bronze_plan) { plans.create(name: 'bronze', title: 'Bronze', active_pipelines_limit: 40, pipeline_size_limit: 41, active_jobs_limit: 42) }
  let!(:free_plan) { plans.create(name: 'free', title: 'Free', active_pipelines_limit: 50, pipeline_size_limit: 51, active_jobs_limit: 52) }
  let!(:other_plan) { plans.create(name: 'other', title: 'Other', active_pipelines_limit: nil, pipeline_size_limit: nil, active_jobs_limit: 0) }

  describe 'migrate' do
    it 'populates plan_limits from all the records in plans' do
      expect { migrate! }.to change { plan_limits.count }.by 6
    end

    it 'copies plan limits and plan.id into to plan_limits table' do
      migrate!

      new_data = plan_limits.pluck(:plan_id, :ci_active_pipelines, :ci_pipeline_size, :ci_active_jobs)
      expected_data = [
        [early_adopter_plan.id, 10, 11, 12],
        [gold_plan.id, 20, 21, 22],
        [silver_plan.id, 30, 31, 32],
        [bronze_plan.id, 40, 41, 42],
        [free_plan.id, 50, 51, 52],
        [other_plan.id, 0, 0, 0]
      ]
      expect(new_data).to contain_exactly(*expected_data)
    end
  end
end
