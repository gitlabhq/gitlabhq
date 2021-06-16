# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe InsertProjectFeatureFlagsPlanLimits do
  let(:migration) { described_class.new }
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }
  let!(:default_plan) { plans.create!(name: 'default') }
  let!(:free_plan) { plans.create!(name: 'free') }
  let!(:bronze_plan) { plans.create!(name: 'bronze') }
  let!(:silver_plan) { plans.create!(name: 'silver') }
  let!(:gold_plan) { plans.create!(name: 'gold') }
  let!(:default_plan_limits) do
    plan_limits.create!(plan_id: default_plan.id, project_feature_flags: 200)
  end

  context 'when on Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).at_most(:twice).and_return(true)
    end

    describe '#up' do
      it 'updates the project_feature_flags plan limits' do
        migration.up

        expect(plan_limits.pluck(:plan_id, :project_feature_flags)).to contain_exactly(
          [default_plan.id, 200],
          [free_plan.id, 50],
          [bronze_plan.id, 100],
          [silver_plan.id, 150],
          [gold_plan.id, 200]
        )
      end
    end

    describe '#down' do
      it 'removes the project_feature_flags plan limits' do
        migration.up
        migration.down

        expect(plan_limits.pluck(:plan_id, :project_feature_flags)).to contain_exactly(
          [default_plan.id, 200],
          [free_plan.id, 0],
          [bronze_plan.id, 0],
          [silver_plan.id, 0],
          [gold_plan.id, 0]
        )
      end
    end
  end

  context 'when on self-hosted' do
    before do
      expect(Gitlab).to receive(:com?).at_most(:twice).and_return(false)
    end

    describe '#up' do
      it 'does not change the plan limits' do
        migration.up

        expect(plan_limits.pluck(:project_feature_flags)).to contain_exactly(200)
      end
    end

    describe '#down' do
      it 'does not change the plan limits' do
        migration.up
        migration.down

        expect(plan_limits.pluck(:project_feature_flags)).to contain_exactly(200)
      end
    end
  end
end
