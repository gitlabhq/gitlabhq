# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdatePipelineTriggersPremiumUltimatePlanLimits, feature_category: :pipeline_composition do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  let!(:premium_plan) { plans.create!(name: 'premium') }
  let!(:ultimate_plan) { plans.create!(name: 'ultimate') }
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
              [premium_plan.id, 0], [ultimate_plan.id, 0], [default_plan.id, 0])
        }

        migration.after -> {
          expect(plan_limits.pluck(:plan_id, :pipeline_triggers))
            .to contain_exactly(
              [premium_plan.id, 25000], [ultimate_plan.id, 25000], [default_plan.id, 0])
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
              [premium_plan.id, 0], [ultimate_plan.id, 0], [default_plan.id, 0])
        }

        migration.after -> {
          expect(plan_limits.pluck(:plan_id, :pipeline_triggers))
            .to contain_exactly(
              [premium_plan.id, 0], [ultimate_plan.id, 0], [default_plan.id, 0])
        }
      end
    end
  end
end
