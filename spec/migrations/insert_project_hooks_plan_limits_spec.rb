# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe InsertProjectHooksPlanLimits do
  let(:migration) { described_class.new }
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  before do
    plans.create!(id: 34, name: 'free')
    plans.create!(id: 2, name: 'bronze')
    plans.create!(id: 3, name: 'silver')
    plans.create!(id: 4, name: 'gold')
    plan_limits.create!(plan_id: 34, ci_active_jobs: 5)
  end

  context 'when on Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).at_most(:twice).and_return(true)
    end

    describe '#up' do
      it 'updates the project_hooks plan limits' do
        migration.up

        expect(plan_limits.pluck(:plan_id, :project_hooks, :ci_active_jobs))
          .to match_array([[34, 10, 5], [2, 20, 0], [3, 30, 0], [4, 100, 0]])
      end
    end

    describe '#down' do
      it 'updates the project_hooks plan limits to 0' do
        migration.up
        migration.down

        expect(plan_limits.pluck(:plan_id, :project_hooks, :ci_active_jobs))
          .to match_array([[34, 0, 5], [2, 0, 0], [3, 0, 0], [4, 0, 0]])
      end
    end
  end

  context 'when on self-hosted' do
    before do
      expect(Gitlab).to receive(:com?).and_return(false)
    end

    describe '#up' do
      it 'does not update the plan limits' do
        migration.up

        expect(plan_limits.pluck(:plan_id, :project_hooks, :ci_active_jobs))
          .to match_array([[34, 0, 5]])
      end
    end

    describe '#down' do
      it 'does not update the plan limits' do
        migration.down

        expect(plan_limits.pluck(:plan_id, :project_hooks, :ci_active_jobs))
          .to match_array([[34, 0, 5]])
      end
    end
  end
end
