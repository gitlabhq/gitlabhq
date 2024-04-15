# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::Revoke, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:group) { create(:group, developers: developer, maintainers: maintainer) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }
  let_it_be(:user_achievement) { create(:user_achievement, achievement: achievement) }

  let(:mutation) { graphql_mutation(:achievements_revoke, params) }
  let(:user_achievement_id) { user_achievement&.to_global_id }
  let(:params) { { user_achievement_id: user_achievement_id } }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:achievements_create)
  end

  context 'when the user does not have permission' do
    let(:current_user) { developer }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not revoke any achievements' do
      expect { subject }.not_to change { Achievements::UserAchievement.where(revoked_by_user_id: nil).count }
    end
  end

  context 'when the user has permission' do
    let(:current_user) { maintainer }

    context 'when the params are invalid' do
      let(:user_achievement) { nil }

      it 'returns the validation error' do
        subject

        expect(graphql_errors.to_s).to include('invalid value for userAchievementId (Expected value to not be null)')
      end
    end

    context 'when the user_achievement_id is invalid' do
      let(:user_achievement_id) { "gid://gitlab/Achievements::UserAchievement/#{non_existing_record_id}" }

      it 'returns the validation error' do
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

    it 'revokes an achievement' do
      expect { subject }.to change { Achievements::UserAchievement.where(revoked_by_user_id: nil).count }.by(-1)
    end

    it 'returns the revoked achievement' do
      subject

      expect(graphql_data_at(:achievements_revoke, :user_achievement, :achievement, :id))
        .to eq(achievement.to_global_id.to_s)
      expect(graphql_data_at(:achievements_revoke, :user_achievement, :revoked_by_user, :id))
        .to eq(current_user.to_global_id.to_s)
      expect(graphql_data_at(:achievements_revoke, :user_achievement, :revoked_at))
        .not_to be_nil
    end
  end
end
