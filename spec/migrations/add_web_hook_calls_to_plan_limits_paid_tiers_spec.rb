# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddWebHookCallsToPlanLimitsPaidTiers, feature_category: :purchase do
  let!(:plans) { table(:plans) }
  let!(:plan_limits) { table(:plan_limits) }

  context 'when on Gitlab.com' do
    let(:free_plan) { plans.create!(name: 'free') }
    let(:bronze_plan) { plans.create!(name: 'bronze') }
    let(:silver_plan) { plans.create!(name: 'silver') }
    let(:gold_plan) { plans.create!(name: 'gold') }
    let(:premium_plan) { plans.create!(name: 'premium') }
    let(:premium_trial_plan) { plans.create!(name: 'premium_trial') }
    let(:ultimate_plan) { plans.create!(name: 'ultimate') }
    let(:ultimate_trial_plan) { plans.create!(name: 'ultimate_trial') }
    let(:opensource_plan) { plans.create!(name: 'opensource') }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      # 120 is the value for 'free' migrated in `db/migrate/20210601131742_update_web_hook_calls_limit.rb`
      plan_limits.create!(plan_id: free_plan.id, web_hook_calls: 120)
      plan_limits.create!(plan_id: bronze_plan.id)
      plan_limits.create!(plan_id: silver_plan.id)
      plan_limits.create!(plan_id: gold_plan.id)
      plan_limits.create!(plan_id: premium_plan.id)
      plan_limits.create!(plan_id: premium_trial_plan.id)
      plan_limits.create!(plan_id: ultimate_plan.id)
      plan_limits.create!(plan_id: ultimate_trial_plan.id)
      plan_limits.create!(plan_id: opensource_plan.id)
    end

    it 'correctly migrates up and down' do
      reversible_migration do |migration|
        migration.before -> {
          expect(
            plan_limits.pluck(:plan_id, :web_hook_calls, :web_hook_calls_mid, :web_hook_calls_low)
          ).to contain_exactly(
            [free_plan.id, 120, 0, 0],
            [bronze_plan.id, 0, 0, 0],
            [silver_plan.id, 0, 0, 0],
            [gold_plan.id, 0, 0, 0],
            [premium_plan.id, 0, 0, 0],
            [premium_trial_plan.id, 0, 0, 0],
            [ultimate_plan.id, 0, 0, 0],
            [ultimate_trial_plan.id, 0, 0, 0],
            [opensource_plan.id, 0, 0, 0]
          )
        }

        migration.after -> {
          expect(
            plan_limits.pluck(:plan_id, :web_hook_calls, :web_hook_calls_mid, :web_hook_calls_low)
          ).to contain_exactly(
            [free_plan.id, 500, 500, 500],
            [bronze_plan.id, 4_000, 2_800, 1_600],
            [silver_plan.id, 4_000, 2_800, 1_600],
            [gold_plan.id, 13_000, 9_000, 6_000],
            [premium_plan.id, 4_000, 2_800, 1_600],
            [premium_trial_plan.id, 4_000, 2_800, 1_600],
            [ultimate_plan.id, 13_000, 9_000, 6_000],
            [ultimate_trial_plan.id, 13_000, 9_000, 6_000],
            [opensource_plan.id, 13_000, 9_000, 6_000]
          )
        }
      end
    end
  end

  context 'when on self hosted' do
    let(:default_plan) { plans.create!(name: 'default') }

    before do
      allow(Gitlab).to receive(:com?).and_return(false)

      plan_limits.create!(plan_id: default_plan.id)
    end

    it 'does nothing' do
      reversible_migration do |migration|
        migration.before -> {
          expect(
            plan_limits.pluck(:plan_id, :web_hook_calls, :web_hook_calls_mid, :web_hook_calls_low)
          ).to contain_exactly(
            [default_plan.id, 0, 0, 0]
          )
        }

        migration.after -> {
          expect(
            plan_limits.pluck(:plan_id, :web_hook_calls, :web_hook_calls_mid, :web_hook_calls_low)
          ).to contain_exactly(
            [default_plan.id, 0, 0, 0]
          )
        }
      end
    end
  end
end
