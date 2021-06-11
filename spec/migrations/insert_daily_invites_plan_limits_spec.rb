# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe InsertDailyInvitesPlanLimits do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }
  let!(:free_plan) { plans.create!(name: 'free') }
  let!(:bronze_plan) { plans.create!(name: 'bronze') }
  let!(:silver_plan) { plans.create!(name: 'silver') }
  let!(:gold_plan) { plans.create!(name: 'gold') }

  context 'when on Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).at_most(:twice).and_return(true)
    end

    it 'correctly migrates up and down' do
      reversible_migration do |migration|
        migration.before -> {
          expect(plan_limits.where.not(daily_invites: 0)).to be_empty
        }

        # Expectations will run after the up migration.
        migration.after -> {
          expect(plan_limits.pluck(:plan_id, :daily_invites)).to contain_exactly(
            [free_plan.id, 20],
            [bronze_plan.id, 0],
            [silver_plan.id, 0],
            [gold_plan.id, 0]
          )
        }
      end
    end
  end

  context 'when on self hosted' do
    before do
      expect(Gitlab).to receive(:com?).at_most(:twice).and_return(false)
    end

    it 'correctly migrates up and down' do
      reversible_migration do |migration|
        migration.before -> {
          expect(plan_limits.pluck(:daily_invites)).to eq []
        }

        migration.after -> {
          expect(plan_limits.pluck(:daily_invites)).to eq []
        }
      end
    end
  end
end
