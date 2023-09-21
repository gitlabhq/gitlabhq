# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::UpdateUserAchievementPrioritiesService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:achievement_owner) { create(:user) }
    let_it_be(:group) { create(:group) }

    let_it_be(:achievement) { create(:achievement, namespace: group) }

    let!(:user_achievement1) do
      create(:user_achievement, achievement: achievement, user: achievement_owner, priority: 0)
    end

    let_it_be(:user_achievement2) { create(:user_achievement, achievement: achievement, user: achievement_owner) }
    let_it_be(:user_achievement3) { create(:user_achievement, achievement: achievement, user: achievement_owner) }

    subject(:response) { described_class.new(current_user, user_achievements).execute }

    context 'when user does not have permission' do
      let(:current_user) { create(:user) }
      let(:user_achievements) { [user_achievement1] }

      it 'returns an error', :aggregate_failures do
        expect(response).to be_error
        expect(response.message).to match_array(["You can't update at least one of the given user achievements."])
      end
    end

    context 'when user has permission' do
      let_it_be_with_reload(:current_user) { achievement_owner }

      context 'with empty input' do
        let(:user_achievements) { [] }

        it 'removes all priorities', :aggregate_failures do
          expect(response).to be_success

          [user_achievement1, user_achievement2, user_achievement3].each do |ua|
            expect(ua.reload.priority).to be_nil
          end
        end
      end

      context 'with prioritised achievements' do
        let(:user_achievements) { [user_achievement3, user_achievement1] }

        it 're-orders the achievements correctly', :aggregate_failures do
          expect(response).to be_success

          expect(user_achievement1.reload.priority).to eq(1)
          expect(user_achievement2.reload.priority).to be_nil
          expect(user_achievement3.reload.priority).to be_zero
        end
      end

      context 'when no achievement is prioritized and no prioritizations are made' do
        let!(:user_achievement1) { create(:user_achievement, achievement: achievement, user: achievement_owner) }

        let(:user_achievements) { [] }

        it 'works without errors', :aggregate_failures do
          expect(response).to be_success

          [user_achievement1, user_achievement2, user_achievement3].each do |ua|
            expect(ua.reload.priority).to be_nil
          end
        end
      end
    end
  end
end
