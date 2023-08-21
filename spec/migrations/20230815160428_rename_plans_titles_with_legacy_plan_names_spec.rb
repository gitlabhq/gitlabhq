# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RenamePlansTitlesWithLegacyPlanNames, feature_category: :subscription_management do
  let(:plans) { table(:plans) }

  let!(:premium_plan) { plans.create!(name: 'premium', title: 'Premium (Formerly Silver)') }
  let!(:ultimate_plan) { plans.create!(name: 'ultimate', title: 'Ultimate (Formerly Gold)') }

  describe '#up' do
    it 'updates the plan titles' do
      expect(premium_plan.title).to eq('Premium (Formerly Silver)')
      expect(ultimate_plan.title).to eq('Ultimate (Formerly Gold)')

      migrate!

      expect(premium_plan.reload.title).to eq('Premium')
      expect(ultimate_plan.reload.title).to eq('Ultimate')
    end
  end
end
