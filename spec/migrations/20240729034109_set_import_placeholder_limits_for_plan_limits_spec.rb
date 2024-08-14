# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetImportPlaceholderLimitsForPlanLimits, feature_category: :importers do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  let(:pluckable_properties) do
    [:plan_id, :import_placeholder_user_limit_tier_1, :import_placeholder_user_limit_tier_2,
      :import_placeholder_user_limit_tier_3, :import_placeholder_user_limit_tier_4]
  end

  before do
    allow(Gitlab).to receive(:com?).and_return(gitlab_com?)
  end

  context 'when on Gitlab.com' do
    let(:gitlab_com?) { true }
    let(:default_plan) { plans.create!(name: 'default') }
    let(:free_plan) { plans.create!(name: 'free') }
    let(:early_adopter_plan) { plans.create!(name: 'early_adopter') }
    let(:bronze_plan) { plans.create!(name: 'bronze') }
    let(:silver_plan) { plans.create!(name: 'silver') }
    let(:gold_plan) { plans.create!(name: 'gold') }
    let(:premium_plan) { plans.create!(name: 'premium') }
    let(:premium_trial_plan) { plans.create!(name: 'premium_trial') }
    let(:ultimate_plan) { plans.create!(name: 'ultimate') }
    let(:ultimate_trial_plan) { plans.create!(name: 'ultimate_trial') }
    let(:ultimate_trial_paid_customer_plan) { plans.create!(name: 'ultimate_trial_paid_customer') }
    let(:opensource_plan) { plans.create!(name: 'opensource') }

    before do
      plan_limits.create!(plan_id: default_plan.id)
      plan_limits.create!(plan_id: free_plan.id)
      plan_limits.create!(plan_id: early_adopter_plan.id)
      plan_limits.create!(plan_id: bronze_plan.id)
      plan_limits.create!(plan_id: silver_plan.id)
      plan_limits.create!(plan_id: gold_plan.id)
      plan_limits.create!(plan_id: premium_plan.id)
      plan_limits.create!(plan_id: premium_trial_plan.id)
      plan_limits.create!(plan_id: ultimate_plan.id)
      plan_limits.create!(plan_id: ultimate_trial_plan.id)
      plan_limits.create!(plan_id: ultimate_trial_paid_customer_plan.id)
      plan_limits.create!(plan_id: opensource_plan.id)
    end

    it 'correctly migrates up and down' do
      reversible_migration do |migration|
        migration.before -> {
          expect(
            plan_limits.pluck(*pluckable_properties)
          ).to contain_exactly(
            [default_plan.id, 0, 0, 0, 0],
            [free_plan.id, 0, 0, 0, 0],
            [early_adopter_plan.id, 0, 0, 0, 0],
            [bronze_plan.id, 0, 0, 0, 0],
            [silver_plan.id, 0, 0, 0, 0],
            [gold_plan.id, 0, 0, 0, 0],
            [premium_plan.id, 0, 0, 0, 0],
            [premium_trial_plan.id, 0, 0, 0, 0],
            [ultimate_plan.id, 0, 0, 0, 0],
            [ultimate_trial_plan.id, 0, 0, 0, 0],
            [ultimate_trial_paid_customer_plan.id, 0, 0, 0, 0],
            [opensource_plan.id, 0, 0, 0, 0]
          )
        }

        migration.after -> {
          expect(
            plan_limits.pluck(*pluckable_properties)
          ).to contain_exactly(
            [default_plan.id, 200, 200, 200, 200],
            [free_plan.id, 200, 200, 200, 200],
            [early_adopter_plan.id, 200, 200, 200, 200],
            [bronze_plan.id, 200, 200, 200, 200],
            [silver_plan.id, 500, 2_000, 4_000, 6_000],
            [gold_plan.id, 1_000, 4_000, 6_000, 8_000],
            [premium_plan.id, 500, 2_000, 4_000, 6_000],
            [premium_trial_plan.id, 200, 200, 200, 200],
            [ultimate_plan.id, 1_000, 4_000, 6_000, 8_000],
            [ultimate_trial_plan.id, 200, 200, 200, 200],
            [ultimate_trial_paid_customer_plan.id, 500, 2_000, 4_000, 6_000],
            [opensource_plan.id, 1_000, 4_000, 6_000, 8_000]
          )
        }
      end
    end
  end

  context 'when on self hosted' do
    let(:gitlab_com?) { false }
    let(:default_plan) { plans.create!(name: 'default') }

    before do
      plan_limits.create!(plan_id: default_plan.id)
    end

    it 'does nothing' do
      reversible_migration do |migration|
        migration.before -> {
          expect(
            plan_limits.pluck(*pluckable_properties)
          ).to contain_exactly(
            [default_plan.id, 0, 0, 0, 0]
          )
        }

        migration.after -> {
          expect(
            plan_limits.pluck(*pluckable_properties)
          ).to contain_exactly(
            [default_plan.id, 0, 0, 0, 0]
          )
        }
      end
    end
  end
end
