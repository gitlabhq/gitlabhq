# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::UpdateUserAchievement, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:maintainer) { create(:user, maintainer_of: [group]) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }
  let_it_be(:user_achievement) do
    create(:user_achievement, achievement: achievement, user: owner, show_on_profile: true)
  end

  let(:mutation) { graphql_mutation(:user_achievements_update, params) }
  let(:user_achievement_id) { user_achievement&.to_global_id }
  let(:params) { { user_achievement_id: user_achievement_id, show_on_profile: false } }

  subject(:mutate!) { post_graphql_mutation(mutation, current_user: current_user) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_user_achievement do
    let(:user) { owner }
    let(:boundary_object) { :user }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

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

    context 'when user tries to update a not allowed field' do
      context 'when user is achievement owner' do
        let(:current_user) { owner }
        let(:params) { { user_achievement_id: user_achievement_id, award_message: 'test' } }

        it 'returns the unmodified user achievement' do
          expect { mutate! }.not_to change { user_achievement.reload.award_message }

          expect(graphql_data_at(:user_achievements_update, :user_achievement, :id))
            .to eq(user_achievement.to_global_id.to_s)
          expect(graphql_data_at(:user_achievements_update, :user_achievement, :award_message)).to be_nil
        end
      end

      context 'when user is achievement awarder' do
        let(:current_user) { maintainer }
        let(:params) { { user_achievement_id: user_achievement_id, show_on_profile: false } }

        it 'returns the unmodified user achievement' do
          expect { mutate! }.not_to change { user_achievement.reload.show_on_profile }

          expect(graphql_data_at(:user_achievements_update, :user_achievement, :id))
            .to eq(user_achievement.to_global_id.to_s)
          expect(graphql_data_at(:user_achievements_update, :user_achievement, :show_on_profile)).to be(true)
        end
      end
    end

    context 'when everything is ok' do
      context 'when user is achievement owner' do
        it 'updates a user achievement' do
          expect { mutate! }.to change { user_achievement.reload.show_on_profile }.from(true).to(false)
        end

        it 'returns the updated user achievement' do
          mutate!

          expect(graphql_data_at(:user_achievements_update, :user_achievement, :id))
            .to eq(user_achievement.to_global_id.to_s)
          expect(graphql_data_at(:user_achievements_update, :user_achievement, :show_on_profile)).to be(false)
        end
      end

      context 'when user is group maintainer' do
        let(:current_user) { maintainer }
        let(:params) { { user_achievement_id: user_achievement_id, award_message: 'test' } }

        it 'updates a user achievement' do
          expect { mutate! }.to change { user_achievement.reload.award_message }.from(nil).to('test')
        end

        it 'returns the updated user achievement' do
          mutate!

          expect(graphql_data_at(:user_achievements_update, :user_achievement, :id))
            .to eq(user_achievement.to_global_id.to_s)
          expect(graphql_data_at(:user_achievements_update, :user_achievement, :award_message)).to eq('test')
        end
      end
    end
  end
end
