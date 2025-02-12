# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangeDefaultActiveVersionedPagesDeploymentLimit, feature_category: :database, migration_version: 20250206114301 do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  describe '#up' do
    it 'does not change the value for the existing default plan' do
      # This scenario will be backfilled in a separate migration
      plan = plans.create!(name: Plan::DEFAULT)
      plan_limits.create!(plan_id: plan.id)

      migrate!

      plan_limit = plan_limits.find_by(plan_id: plan.id)
      expect(plan_limit.active_versioned_pages_deployments_limit_by_namespace).to eq(0)
    end

    it 'ensures new plan_limits records (if created after this migration) have the new default' do
      migrate!

      plan = plans.create!(name: Plan::DEFAULT)
      plan_limits.create!(plan_id: plan.id)
      plan_limit = plan_limits.find_by(plan_id: plan.id)

      expect(plan_limit.active_versioned_pages_deployments_limit_by_namespace).to eq(1000)
    end
  end
end
