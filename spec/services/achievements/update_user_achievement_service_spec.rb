# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::UpdateUserAchievementService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:achievement_owner) { create(:user) }
    let_it_be(:user_achievement) { create(:user_achievement, user: achievement_owner) }

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
      let(:current_user) { achievement_owner }

      it 'updates the achievement' do
        expect(response).to be_success
        expect(user_achievement.reload.show_on_profile).to eq(false)
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
