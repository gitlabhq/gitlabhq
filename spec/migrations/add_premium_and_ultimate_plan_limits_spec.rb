# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddPremiumAndUltimatePlanLimits, :migration do
  shared_examples_for 'a migration that does not alter plans or plan limits' do
    it do
      expect { migrate! }.not_to change {
        [
          AddPremiumAndUltimatePlanLimits::Plan.count,
          AddPremiumAndUltimatePlanLimits::PlanLimits.count
        ]
      }
    end
  end

  describe '#up' do
    context 'when not .com?' do
      before do
        allow(Gitlab).to receive(:com?).and_return false
      end

      it_behaves_like 'a migration that does not alter plans or plan limits'
    end

    context 'when .com?' do
      before do
        allow(Gitlab).to receive(:com?).and_return true
      end

      context 'when source plan does not exist' do
        it_behaves_like 'a migration that does not alter plans or plan limits'
      end

      context 'when target plan does not exist' do
        before do
          table(:plans).create!(name: 'silver', title: 'Silver')
          table(:plans).create!(name: 'gold', title: 'Gold')
        end

        it_behaves_like 'a migration that does not alter plans or plan limits'
      end

      context 'when source and target plans exist' do
        let!(:silver) { table(:plans).create!(name: 'silver', title: 'Silver') }
        let!(:gold) { table(:plans).create!(name: 'gold', title: 'Gold') }
        let!(:premium) { table(:plans).create!(name: 'premium', title: 'Premium') }
        let!(:ultimate) { table(:plans).create!(name: 'ultimate', title: 'Ultimate') }

        let!(:silver_limits) { table(:plan_limits).create!(plan_id: silver.id, storage_size_limit: 111) }
        let!(:gold_limits) { table(:plan_limits).create!(plan_id: gold.id, storage_size_limit: 222) }

        context 'when target has plan limits' do
          before do
            table(:plan_limits).create!(plan_id: premium.id, storage_size_limit: 999)
            table(:plan_limits).create!(plan_id: ultimate.id, storage_size_limit: 999)
          end

          it 'does not overwrite the limits' do
            expect { migrate! }.not_to change {
              [
                AddPremiumAndUltimatePlanLimits::Plan.count,
                AddPremiumAndUltimatePlanLimits::PlanLimits.pluck(:id, :storage_size_limit).sort
              ]
            }
          end
        end

        context 'when target has no plan limits' do
          it 'creates plan limits from the source plan' do
            migrate!

            expect(AddPremiumAndUltimatePlanLimits::PlanLimits.pluck(:plan_id, :storage_size_limit)).to match_array([
              [silver.id, silver_limits.storage_size_limit],
              [gold.id, gold_limits.storage_size_limit],
              [premium.id, silver_limits.storage_size_limit],
              [ultimate.id, gold_limits.storage_size_limit]
            ])
          end
        end
      end
    end
  end
end
