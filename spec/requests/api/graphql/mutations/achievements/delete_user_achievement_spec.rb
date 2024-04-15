# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::DeleteUserAchievement, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) { create(:group, maintainers: maintainer, owners: owner) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }
  let_it_be(:user_achievement) { create(:user_achievement, achievement: achievement) }

  let(:mutation) { graphql_mutation(:user_achievements_delete, params) }
  let(:user_achievement_id) { user_achievement&.to_global_id }
  let(:params) { { user_achievement_id: user_achievement_id } }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when the user does not have permission' do
    let(:current_user) { maintainer }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not delete any user achievements' do
      expect { subject }.not_to change { Achievements::UserAchievement.count }
    end
  end

  context 'when the user has permission' do
    let(:current_user) { owner }

    context 'when the params are invalid' do
      let(:user_achievement) { nil }

      it 'returns the validation error' do
        subject

        expect(graphql_errors.to_s).to include('invalid value for userAchievementId (Expected value to not be null)')
      end
    end

    context 'when the user_achievement_id is invalid' do
      let(:user_achievement_id) { "gid://gitlab/Achievements::UserAchievement/#{non_existing_record_id}" }

      it 'returns the relevant error' do
        subject

        expect(graphql_errors.to_s)
          .to include("The resource that you are attempting to access does not exist or you don't have permission")
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(achievements: false)
      end

      it 'returns the relevant error' do
        subject

        expect(graphql_errors.to_s)
          .to include("The resource that you are attempting to access does not exist or you don't have permission")
      end
    end

    context 'when everything is ok' do
      it 'deletes an user achievement' do
        expect { subject }.to change { Achievements::UserAchievement.count }.by(-1)
      end

      it 'returns the deleted user achievement' do
        subject

        expect(graphql_data_at(:user_achievements_delete, :user_achievement, :achievement, :id))
          .to eq(achievement.to_global_id.to_s)
      end
    end
  end
end
