# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateTrialPlansCiDailyPipelineScheduleTriggers, :migration, feature_category: :purchase do
  let!(:plans) { table(:plans) }
  let!(:plan_limits) { table(:plan_limits) }
  let!(:premium_trial_plan) { plans.create!(name: 'premium_trial', title: 'Premium Trial') }
  let!(:ultimate_trial_plan) { plans.create!(name: 'ultimate_trial', title: 'Ultimate Trial') }

  describe '#up' do
    let!(:premium_trial_plan_limits) { plan_limits.create!(plan_id: premium_trial_plan.id, ci_daily_pipeline_schedule_triggers: 0) }
    let!(:ultimate_trial_plan_limits) { plan_limits.create!(plan_id: ultimate_trial_plan.id, ci_daily_pipeline_schedule_triggers: 0) }

    context 'when the environment is dev or com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'sets the trial plan limits for ci_daily_pipeline_schedule_triggers' do
        disable_migrations_output { migrate! }

        expect(ultimate_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(288)
        expect(premium_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(288)
      end

      it 'does not change the plan limits if the ultimate trial plan is missing' do
        ultimate_trial_plan.destroy!

        expect { disable_migrations_output { migrate! } }.not_to change { plan_limits.count }
        expect(premium_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(0)
      end

      it 'does not change the plan limits if the ultimate trial plan limits is missing' do
        ultimate_trial_plan_limits.destroy!

        expect { disable_migrations_output { migrate! } }.not_to change { plan_limits.count }
        expect(premium_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(0)
      end

      it 'does not change the plan limits if the premium trial plan is missing' do
        premium_trial_plan.destroy!

        expect { disable_migrations_output { migrate! } }.not_to change { plan_limits.count }
        expect(ultimate_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(0)
      end

      it 'does not change the plan limits if the premium trial plan limits is missing' do
        premium_trial_plan_limits.destroy!

        expect { disable_migrations_output { migrate! } }.not_to change { plan_limits.count }
        expect(ultimate_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(0)
      end
    end

    context 'when the environment is anything other than dev or com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not update the plan limits' do
        disable_migrations_output { migrate! }

        expect(premium_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(0)
        expect(ultimate_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(0)
      end
    end
  end

  describe '#down' do
    let!(:premium_trial_plan_limits) { plan_limits.create!(plan_id: premium_trial_plan.id, ci_daily_pipeline_schedule_triggers: 288) }
    let!(:ultimate_trial_plan_limits) { plan_limits.create!(plan_id: ultimate_trial_plan.id, ci_daily_pipeline_schedule_triggers: 288) }

    context 'when the environment is dev or com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'sets the trial plan limits ci_daily_pipeline_schedule_triggers to zero' do
        migrate_down!

        expect(ultimate_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(0)
        expect(premium_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(0)
      end

      it 'does not change the plan limits if the ultimate trial plan is missing' do
        ultimate_trial_plan.destroy!

        expect { migrate_down! }.not_to change { plan_limits.count }
        expect(premium_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(288)
      end

      it 'does not change the plan limits if the ultimate trial plan limits is missing' do
        ultimate_trial_plan_limits.destroy!

        expect { migrate_down! }.not_to change { plan_limits.count }
        expect(premium_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(288)
      end

      it 'does not change the plan limits if the premium trial plan is missing' do
        premium_trial_plan.destroy!

        expect { migrate_down! }.not_to change { plan_limits.count }
        expect(ultimate_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(288)
      end

      it 'does not change the plan limits if the premium trial plan limits is missing' do
        premium_trial_plan_limits.destroy!

        expect { migrate_down! }.not_to change { plan_limits.count }
        expect(ultimate_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(288)
      end
    end

    context 'when the environment is anything other than dev or com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not change the ultimate trial plan limits' do
        migrate_down!

        expect(ultimate_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(288)
        expect(premium_trial_plan_limits.reload.ci_daily_pipeline_schedule_triggers).to eq(288)
      end
    end
  end

  def migrate_down!
    disable_migrations_output do
      migrate!
      described_class.new.down
    end
  end
end
