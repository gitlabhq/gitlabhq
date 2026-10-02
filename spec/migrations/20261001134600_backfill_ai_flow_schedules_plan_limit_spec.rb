# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillAiFlowSchedulesPlanLimit, migration: :gitlab_main, feature_category: :code_suggestions do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  let!(:free_limits) { create_plan_limits!('free', 2, ai_flow_schedules: 10) }
  let!(:ultimate_limits) { create_plan_limits!('ultimate', 7, ai_flow_schedules: 10) }
  let!(:customized_limits) { create_plan_limits!('premium', 5, ai_flow_schedules: 25) }

  def create_plan_limits!(plan_name, plan_name_uid, **attributes)
    plan = plans.create!(name: plan_name, plan_name_uid: plan_name_uid)

    plan_limits.create!(plan_id: plan.id, **attributes)
  end

  describe '#up' do
    it 'raises the limit to 100 for plans still on the old default', :aggregate_failures do
      migrate!

      expect(free_limits.reload.ai_flow_schedules).to eq(100)
      expect(ultimate_limits.reload.ai_flow_schedules).to eq(100)
    end

    it 'leaves a customized limit alone' do
      migrate!

      expect(customized_limits.reload.ai_flow_schedules).to eq(25)
    end

    it 'does not create limits for plans that have none' do
      plans.create!(name: 'opensource', plan_name_uid: 11)

      expect { migrate! }.not_to change { plan_limits.count }
    end
  end

  describe '#down' do
    it 'restores the old default for plans it raised', :aggregate_failures do
      migrate!
      schema_migrate_down!

      expect(free_limits.reload.ai_flow_schedules).to eq(10)
      expect(ultimate_limits.reload.ai_flow_schedules).to eq(10)
    end

    it 'leaves a customized limit alone' do
      migrate!
      schema_migrate_down!

      expect(customized_limits.reload.ai_flow_schedules).to eq(25)
    end
  end
end
