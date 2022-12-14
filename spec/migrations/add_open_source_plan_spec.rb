# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddOpenSourcePlan, :migration, feature_category: :purchase do
  describe '#up' do
    before do
      allow(Gitlab).to receive(:com?).and_return true
    end

    it 'creates 1 entry within the plans table' do
      expect { migrate! }.to change { AddOpenSourcePlan::Plan.count }.by 1
      expect(AddOpenSourcePlan::Plan.last.name).to eql('opensource')
    end

    it 'creates 1 entry for plan limits' do
      expect { migrate! }.to change { AddOpenSourcePlan::PlanLimits.count }.by 1
    end

    context 'when the plan limits for gold and silver exists' do
      before do
        table(:plans).create!(id: 1, name: 'ultimate', title: 'Ultimate')
        table(:plan_limits).create!(id: 1, plan_id: 1, storage_size_limit: 2000)
      end

      it 'duplicates the gold and silvers plan limits entries' do
        migrate!

        opensource_limits = AddOpenSourcePlan::Plan.find_by(name: 'opensource').limits
        expect(opensource_limits.storage_size_limit).to be 2000
      end
    end

    context 'when the instance is not SaaS' do
      before do
        allow(Gitlab).to receive(:com?).and_return false
      end

      it 'does not create plans and plan limits and returns' do
        expect { migrate! }.not_to change { AddOpenSourcePlan::Plan.count }
      end
    end
  end

  describe '#down' do
    before do
      table(:plans).create!(id: 3, name: 'other')
      table(:plan_limits).create!(plan_id: 3)
    end

    context 'when the instance is SaaS' do
      before do
        allow(Gitlab).to receive(:com?).and_return true
      end

      it 'removes the newly added opensource entry' do
        migrate!

        expect { described_class.new.down }.to change { AddOpenSourcePlan::Plan.count }.by(-1)
        expect(AddOpenSourcePlan::Plan.find_by(name: 'opensource')).to be_nil

        other_plan = AddOpenSourcePlan::Plan.find_by(name: 'other')
        expect(other_plan).to be_persisted
        expect(AddOpenSourcePlan::PlanLimits.count).to eq(1)
        expect(AddOpenSourcePlan::PlanLimits.first.plan_id).to eq(other_plan.id)
      end
    end

    context 'when the instance is not SaaS' do
      before do
        allow(Gitlab).to receive(:com?).and_return false
        table(:plans).create!(id: 1, name: 'opensource', title: 'Open Source Program')
        table(:plan_limits).create!(id: 1, plan_id: 1)
      end

      it 'does not delete plans and plan limits and returns' do
        migrate!

        expect { described_class.new.down }.not_to change { AddOpenSourcePlan::Plan.count }
        expect(AddOpenSourcePlan::PlanLimits.count).to eq(2)
      end
    end
  end
end
