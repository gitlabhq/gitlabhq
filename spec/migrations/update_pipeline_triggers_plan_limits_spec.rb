# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdatePipelineTriggersPlanLimits, feature_category: :pipeline_composition do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  let!(:premium_trial_plan) { plans.create!(name: 'premium_trial') }
  let!(:ultimate_trial_plan) { plans.create!(name: 'ultimate_trial') }
  let!(:opensource_plan) { plans.create!(name: 'opensource') }
  let!(:default_plan) { plans.create!(name: 'default') }

  before do
    plans.pluck(:id).each { |plan_id| plan_limits.create!(plan_id: plan_id) }
    plan_limits.update_all(pipeline_triggers: 0)
  end

  context 'when on gitlab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'correctly migrates up and down' do
      reversible_migration do |migration|
        migration.before -> {
          expect(plan_limits.pluck(:plan_id, :pipeline_triggers))
            .to contain_exactly(
              [premium_trial_plan.id, 0], [ultimate_trial_plan.id, 0], [opensource_plan.id, 0], [default_plan.id, 0])
        }

        migration.after -> {
          expect(plan_limits.pluck(:plan_id, :pipeline_triggers))
            .to contain_exactly(
              [premium_trial_plan.id, 25000], [ultimate_trial_plan.id, 25000], [opensource_plan.id, 25000],
              [default_plan.id, 0])
        }
      end
    end
  end

  context 'when on self-managed' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

    it 'correctly migrates up and down' do
      reversible_migration do |migration|
        migration.before -> {
          expect(plan_limits.pluck(:plan_id, :pipeline_triggers))
            .to contain_exactly(
              [premium_trial_plan.id, 0], [ultimate_trial_plan.id, 0], [opensource_plan.id, 0], [default_plan.id, 0])
        }

        migration.after -> {
          expect(plan_limits.pluck(:plan_id, :pipeline_triggers))
            .to contain_exactly(
              [premium_trial_plan.id, 0], [ultimate_trial_plan.id, 0], [opensource_plan.id, 0], [default_plan.id, 0])
        }
      end
    end
  end
end
