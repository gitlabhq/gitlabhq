# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::UpdateUserAchievementPriorities, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }

  let_it_be(:user_achievement1) do
    create(:user_achievement, achievement: achievement, user: user, priority: 0)
  end

  let_it_be(:user_achievement2) { create(:user_achievement, achievement: achievement, user: user) }
  let_it_be(:user_achievement3) { create(:user_achievement, achievement: achievement, user: user) }

  let(:mutation) { graphql_mutation(:user_achievement_priorities_update, params) }
  let(:user_achievement_ids) { [user_achievement3, user_achievement1].map(&:to_global_id) }
  let(:params) { { user_achievement_ids: user_achievement_ids } }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:user_achievement_priorities_update)
  end

  context 'when the user is not the user achievement owner' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ["The resource that you are attempting to access does not exist " \
               "or you don't have permission to perform this action"]

    it 'does not update any achievements', :aggregate_failures do
      subject

      expect(user_achievement1.reload.priority).to be_zero
      expect(user_achievement2.reload.priority).to be_nil
      expect(user_achievement3.reload.priority).to be_nil
    end
  end

  context 'when the user is the user achievement owner' do
    let(:current_user) { user }

    context 'when the params are invalid' do
      let(:user_achievement_ids) { nil }

      it 'returns the validation error' do
        subject

        expect(graphql_errors.to_s).to include('invalid value for userAchievementIds (Expected value to not be null)')
      end
    end

    context 'when a user_achievement_id is invalid' do
      let(:user_achievement_ids) { ["gid://gitlab/Achievements::UserAchievement/#{non_existing_record_id}"] }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ["The resource that you are attempting to access does not exist " \
                 "or you don't have permission to perform this action"]
    end

    context 'when updating priorities' do
      it 'updates only the given user achievements', :aggregate_failures do
        subject

        expect(graphql_data_at(:user_achievement_priorities_update, :user_achievements))
          .to contain_exactly(a_graphql_entity_for(user_achievement3), a_graphql_entity_for(user_achievement1))

        expect(user_achievement3.reload.priority).to eq(0)
        expect(user_achievement1.reload.priority).to eq(1)
        expect(user_achievement2.reload.priority).to be_nil
      end
    end

    context 'when no achievement ids are given' do
      let(:user_achievement_ids) { [] }

      it 'removes all priorities', :aggregate_failures do
        subject

        expect(graphql_data_at(:user_achievement_priorities_update, :user_achievements))
          .to contain_exactly(a_graphql_entity_for(user_achievement1)) # user_achievement1 was prioritized before

        [user_achievement1, user_achievement2, user_achievement3].each do |ua|
          expect(ua.reload.priority).to be_nil
        end
      end
    end
  end
end
