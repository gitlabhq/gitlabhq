# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::UpdateUserAchievementService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:achievement_owner) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:achievement) { create(:achievement, namespace: group) }
    let_it_be(:group_maintainer) { create(:user, maintainer_of: [group]) }
    let_it_be_with_reload(:user_achievement) do
      create(:user_achievement, achievement: achievement, user: achievement_owner)
    end

    let(:params) do
      { show_on_profile: false }
    end

    subject(:response) { described_class.new(current_user, user_achievement, params).execute }

    context 'when user does not have permission' do
      let(:current_user) { create(:user) }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(
          ['You have insufficient permission to update this user achievement'])
      end
    end

    context 'when user has permission' do
      context 'when user is achievement owner' do
        let(:current_user) { achievement_owner }

        it 'updates the achievement' do
          expect(response).to be_success
          expect(user_achievement.reload.show_on_profile).to be(false)
        end
      end

      context 'when user is group maintainer' do
        let(:current_user) { group_maintainer }
        let(:params) { { award_message: 'test' } }

        it 'updates the achievement' do
          expect(response).to be_success
          expect(user_achievement.reload.award_message).to eq('test')
        end
      end

      context 'when user is not allowed to update a specific field' do
        context 'when user is achievement owner' do
          let(:current_user) { achievement_owner }
          let(:params) { { award_message: 'test' } }

          it 'does not update award_message' do
            expect(response).to be_success
            expect(user_achievement.reload.award_message).to be_nil
          end
        end

        context 'when user is group maintainer' do
          let(:current_user) { group_maintainer }
          let(:params) { { show_on_profile: true } }

          it 'does not update show_on_profile' do
            expect(response).to be_success
            expect(user_achievement.reload.show_on_profile).to be false
          end
        end
      end
    end

    context 'when params are invalid' do
      let(:current_user) { achievement_owner }
      let(:params) do
        { show_on_profile: nil }
      end

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(['Show on profile is not included in the list'])
      end
    end
  end
end
