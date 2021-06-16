# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20210526190553_insert_ci_daily_pipeline_schedule_triggers_plan_limits.rb')

RSpec.describe InsertCiDailyPipelineScheduleTriggersPlanLimits do
  let_it_be(:plans) { table(:plans) }
  let_it_be(:plan_limits) { table(:plan_limits) }

  context 'when on Gitlab.com' do
    let(:free_plan) { plans.create!(name: 'free') }
    let(:bronze_plan) { plans.create!(name: 'bronze') }
    let(:silver_plan) { plans.create!(name: 'silver') }
    let(:gold_plan) { plans.create!(name: 'gold') }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)

      plan_limits.create!(plan_id: free_plan.id)
      plan_limits.create!(plan_id: bronze_plan.id)
      plan_limits.create!(plan_id: silver_plan.id)
      plan_limits.create!(plan_id: gold_plan.id)
    end

    it 'correctly migrates up and down' do
      reversible_migration do |migration|
        migration.before -> {
          expect(plan_limits.pluck(:plan_id, :ci_daily_pipeline_schedule_triggers)).to contain_exactly(
            [free_plan.id, 0],
            [bronze_plan.id, 0],
            [silver_plan.id, 0],
            [gold_plan.id, 0]
          )
        }

        migration.after -> {
          expect(plan_limits.pluck(:plan_id, :ci_daily_pipeline_schedule_triggers)).to contain_exactly(
            [free_plan.id, 24],
            [bronze_plan.id, 288],
            [silver_plan.id, 288],
            [gold_plan.id, 288]
          )
        }
      end
    end
  end

  context 'when on self hosted' do
    let(:free_plan) { plans.create!(name: 'free') }

    before do
      allow(Gitlab).to receive(:com?).and_return(false)

      plan_limits.create!(plan_id: free_plan.id)
    end

    it 'does nothing' do
      reversible_migration do |migration|
        migration.before -> {
          expect(plan_limits.pluck(:plan_id, :ci_daily_pipeline_schedule_triggers)).to contain_exactly(
            [free_plan.id, 0]
          )
        }

        migration.after -> {
          expect(plan_limits.pluck(:plan_id, :ci_daily_pipeline_schedule_triggers)).to contain_exactly(
            [free_plan.id, 0]
          )
        }
      end
    end
  end
end
