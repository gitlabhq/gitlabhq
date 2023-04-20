# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe InsertDailyInvitesTrialPlanLimits, feature_category: :subgroups do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }
  let!(:premium_trial_plan) { plans.create!(name: 'premium_trial') }
  let!(:ultimate_trial_plan) { plans.create!(name: 'ultimate_trial') }

  context 'when on gitlab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'correctly migrates up and down' do
      reversible_migration do |migration|
        migration.before -> {
          trial_plan_ids = [premium_trial_plan.id, ultimate_trial_plan.id]
          expect(plan_limits.where(plan_id: trial_plan_ids).where.not(daily_invites: 0)).to be_empty
        }

        migration.after -> {
          expect(plan_limits.pluck(:plan_id, :daily_invites))
            .to contain_exactly([premium_trial_plan.id, 50], [ultimate_trial_plan.id, 50])
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
        trial_plan_ids = [premium_trial_plan.id, ultimate_trial_plan.id]

        migration.before -> {
          expect(plan_limits.where(plan_id: trial_plan_ids).where.not(daily_invites: 0)).to be_empty
        }

        migration.after -> {
          expect(plan_limits.where(plan_id: trial_plan_ids).where.not(daily_invites: 0)).to be_empty
        }
      end
    end
  end
end
