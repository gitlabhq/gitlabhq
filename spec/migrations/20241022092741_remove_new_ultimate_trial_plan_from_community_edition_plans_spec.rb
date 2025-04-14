# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveNewUltimateTrialPlanFromCommunityEditionPlans, feature_category: :plan_provisioning do
  let(:plans) { table(:plans) }
  let(:plan_name) { 'ultimate_trial_paid_customer' }

  before do
    plans.create!(name: 'opensource')
    plans.create!(name: 'default')
  end

  context 'when on self-managed' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

    describe '#up' do
      before do
        plans.create!(name: plan_name) unless new_plan
      end

      it 'deletes the newly added row' do
        expect(new_plan).to be_present

        expect { migrate! }.to change { plans.count }.by(-1)

        expect(new_plan).to be_nil
      end
    end

    describe '#down' do
      it 'adds a new entry to the plans table' do
        migrate!

        expect(new_plan).to be_nil

        expect { schema_migrate_down! }.to change { plans.count }.by(1)

        expect(new_plan).to be_present
      end
    end
  end

  context 'when on gitlab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      plans.create!(name: plan_name) unless new_plan
    end

    describe '#up' do
      it 'does not delete any entries from the plans table' do
        expect { migrate! }.not_to change { plans.count }
      end
    end

    describe '#down' do
      it 'does not add any new entries to the plans table' do
        expect(new_plan).to be_present

        migrate!

        expect(new_plan).to be_present

        expect { schema_migrate_down! }.not_to change { plans.count }
      end
    end
  end

  def new_plan
    plans.find_by(name: plan_name)
  end
end
