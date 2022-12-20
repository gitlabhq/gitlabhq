# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangePublicProjectsCostFactor, migration: :gitlab_ci, feature_category: :runner do
  let(:runners) { table(:ci_runners) }

  let!(:shared_1) { runners.create!(runner_type: 1, public_projects_minutes_cost_factor: 0) }
  let!(:shared_2) { runners.create!(runner_type: 1, public_projects_minutes_cost_factor: 0) }
  let!(:shared_3) { runners.create!(runner_type: 1, public_projects_minutes_cost_factor: 1) }
  let!(:group_1)  { runners.create!(runner_type: 2, public_projects_minutes_cost_factor: 0) }

  describe '#up' do
    context 'when on SaaS' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'updates the cost factor from 0 only for shared runners', :aggregate_failures do
        migrate!

        expect(shared_1.reload.public_projects_minutes_cost_factor).to eq(0.008)
        expect(shared_2.reload.public_projects_minutes_cost_factor).to eq(0.008)
        expect(shared_3.reload.public_projects_minutes_cost_factor).to eq(1)
        expect(group_1.reload.public_projects_minutes_cost_factor).to eq(0)
      end
    end

    context 'when on self-managed', :aggregate_failures do
      it 'skips the migration' do
        migrate!

        expect(shared_1.public_projects_minutes_cost_factor).to eq(0)
        expect(shared_2.public_projects_minutes_cost_factor).to eq(0)
        expect(shared_3.public_projects_minutes_cost_factor).to eq(1)
        expect(group_1.public_projects_minutes_cost_factor).to eq(0)
      end
    end
  end

  describe '#down' do
    context 'when on SaaS' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'resets the cost factor to 0 only for shared runners that were updated', :aggregate_failures do
        migrate!
        schema_migrate_down!

        expect(shared_1.public_projects_minutes_cost_factor).to eq(0)
        expect(shared_2.public_projects_minutes_cost_factor).to eq(0)
        expect(shared_3.public_projects_minutes_cost_factor).to eq(1)
        expect(group_1.public_projects_minutes_cost_factor).to eq(0)
      end
    end
  end
end
