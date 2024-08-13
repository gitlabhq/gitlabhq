# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::UpdateUserAchievement, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:user_achievement) { create(:user_achievement, user: owner) }

  let(:mutation) { graphql_mutation(:user_achievements_update, params) }
  let(:user_achievement_id) { user_achievement&.to_global_id }
  let(:params) { { user_achievement_id: user_achievement_id, show_on_profile: false } }

  subject(:mutate!) { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when the user does not have permission' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update user achievement' do
      expect { mutate! }.not_to change { user_achievement.reload.show_on_profile }
    end
  end

  context 'when the user has permission' do
    let(:current_user) { owner }

    context 'when the params are invalid' do
      let(:user_achievement) { nil }

      it 'returns the validation error' do
        mutate!

        expect(graphql_errors.to_s).to include('invalid value for userAchievementId (Expected value to not be null)')
      end
    end

    context 'when the user_achievement_id is invalid' do
      let(:user_achievement_id) { "gid://gitlab/Achievements::UserAchievement/#{non_existing_record_id}" }

      it 'returns the relevant error' do
        mutate!

        expect(graphql_errors.to_s)
          .to include("The resource that you are attempting to access does not exist or you don't have permission")
      end
    end

    context 'when everything is ok' do
      it 'updates an user achievement' do
        expect { mutate! }.to change { user_achievement.reload.show_on_profile }.from(true).to(false)
      end

      it 'returns the updated user achievement' do
        mutate!

        expect(graphql_data_at(:user_achievements_update, :user_achievement, :id))
          .to eq(user_achievement.to_global_id.to_s)
        expect(graphql_data_at(:user_achievements_update, :user_achievement, :show_on_profile)).to eq(false)
      end
    end
  end
end
