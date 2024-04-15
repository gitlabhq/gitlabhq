# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::Award, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:group) { create(:group, developers: developer, maintainers: maintainer) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }
  let_it_be(:recipient) { create(:user) }

  let(:mutation) { graphql_mutation(:achievements_award, params) }
  let(:achievement_id) { achievement&.to_global_id }
  let(:recipient_id) { recipient&.to_global_id }
  let(:params) do
    {
      achievement_id: achievement_id,
      user_id: recipient_id
    }
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:achievements_create)
  end

  context 'when the user does not have permission' do
    let(:current_user) { developer }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create an achievement' do
      expect { subject }.not_to change { Achievements::UserAchievement.count }
    end
  end

  context 'when the user has permission' do
    let(:current_user) { maintainer }

    context 'when the params are invalid' do
      let(:achievement) { nil }

      it 'returns the validation error' do
        subject

        expect(graphql_errors.to_s).to include('invalid value for achievementId (Expected value to not be null)')
      end
    end

    context 'when the recipient_id is invalid' do
      let(:recipient_id) { "gid://gitlab/User/#{non_existing_record_id}" }

      it 'returns the validation error' do
        subject

        expect(graphql_data_at(:achievements_award,
          :errors)).to include("Couldn't find User with 'id'=#{non_existing_record_id}")
      end
    end

    context 'when the achievement_id is invalid' do
      let(:achievement_id) { "gid://gitlab/Achievements::Achievement/#{non_existing_record_id}" }

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

    it 'creates an achievement' do
      expect { subject }.to change { Achievements::UserAchievement.count }.by(1)
    end

    it 'returns the new achievement' do
      subject

      expect(graphql_data_at(:achievements_award, :user_achievement, :achievement, :id))
        .to eq(achievement.to_global_id.to_s)
      expect(graphql_data_at(:achievements_award, :user_achievement, :user, :id))
        .to eq(recipient.to_global_id.to_s)
    end
  end
end
