# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillDefaultPagesDeploymentLimit, feature_category: :database, migration_version: 20250207141159 do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  let!(:default_plan) { plans.create!(name: Plan::DEFAULT) }

  before do
    plan_limits.create!(
      plan_id: default_plan.id,
      active_versioned_pages_deployments_limit_by_namespace: initial_value
    )
  end

  describe '#up' do
    context 'when the default plan has a limit of 0' do
      let(:initial_value) { 0 }

      it 'updates the limit to 1000' do
        migrate!

        plan_limit = plan_limits.find_by(plan_id: default_plan.id)
        expect(plan_limit.active_versioned_pages_deployments_limit_by_namespace).to eq(1000)
      end
    end
  end

  describe '#down' do
    context 'when the default plan had a non-zero limit before' do
      let(:initial_value) { 1000 }
      let(:migration) { described_class.new }

      it 'resets the limit to 0' do
        migration.down

        plan_limit = plan_limits.find_by(plan_id: default_plan.id)
        expect(plan_limit.active_versioned_pages_deployments_limit_by_namespace).to eq(0)
      end
    end
  end
end
