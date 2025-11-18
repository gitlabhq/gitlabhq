# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillPlanNameUidOnPlans, feature_category: :plan_provisioning do
  describe '#up' do
    it 'backfills plan_name_uid' do
      # Using wrong plan_name_uid value to create a valid record for backfilling
      table(:plans).create!(name: 'premium', title: 'Premium', plan_name_uid: 999)

      migrate!

      expect(table(:plans).find_by(name: 'premium').plan_name_uid).to eq(5)
    end
  end
end
